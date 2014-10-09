//
//  OPhoneNumberFormatter.m
//  OrigoApp
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#import "OPhoneNumberFormatter.h"

static NSString * const kRegionIdentifiersByCountryCallingCode = @"1:US|en_CA|fr_CA|AS|AI|AG|BS|BB|BM|VG|KY|DM|DO|GD|GU|JM|MS|MP|PR|KN|LC|VC|SX|TT|TC|VI;33:FR;34:ES;45:DK;46:SE;47:NO";
static NSString * const kInternationalTemplate = @"+{1|20|21#|22#|23#|24#|25#|26#|27|29#|30|31|32|33|34|35#|36|37#|8#|39|40|41|42#|43|44|45|46|47|48|49|50#|51|52|53|54|55|56|57|58|59#|60|61|62|63|64|65|66|67#|68#|69#|7|80#|81|82|84|85#|86|878|88#|90|91|92|93|94|95|96#|97#|98|99#} #@";
static NSString * const kTemplatesByRegionCode =
@"US|AS|AI|AG|BS|BB|BM|VG|KY|DM|DO|GD|GU|JM|MS|MP|PR|KN|LC|VC|SX|TT|TC|VI:[[[+]1 ]^(N##) ]^N##-####;" \
    "en_CA:[[[+]1-]^N##-]^N##-####;" \
    "fr_CA:[[[+]1 ]^N## ]^N##-####;" \
    "FR:{+33 |^0}# ## ## ## ##;" \
    "ES:[+34 ]^{6|7|8|9}## ### ###;" \
    "DK:[+45 ]^N# ## ## ##;" \
    "NO:[+47 ]^{{4|8|9}## ## ###|N# ## ## ##}";

static NSString * const kTemplateGeneric = @"^[0]#* #@";
static NSString * const kFormatTokens = @"^*@+0123456789#N-()/ ";
static NSString * const kWildcardTokens = @"*@";
static NSString * const kCharacters2_9 = @"23456789";
static NSString * const kWhitespaceCharacters = @"-()/ ";
static NSString * const kPrintableCharacters = @"+0123456789-()/ ";
static NSString * const kFlattenedPhoneNumberCharacters = @"+0123456789";


static NSString * const kTokenCanonical = @"^";
static NSString * const kTokenOptionalBegin = @"[";
static NSString * const kTokenOptionalEnd = @"]";
static NSString * const kTokenGroupBegin = @"{";
static NSString * const kTokenGroupSeparator = @"|";
static NSString * const kTokenGroupEnd = @"}";
static NSString * const kTokenPlus = @"+";
static NSString * const kTokenNumberAny = @"#";
static NSString * const kTokenNumber2_9 = @"N";
static NSString * const kTokenWildcardStrict = @"*";
static NSString * const kTokenWildcardTolerant = @"@";

static NSArray *_internationalFormats;
static NSArray *_supportedRegionIdentifiers = nil;
static NSMutableDictionary *_regionIdentifiersByCountryCallingCode = nil;
static NSMutableDictionary *_templatesByRegionIdentifier = nil;
static NSMutableDictionary *_formattersByRegionIdentifier = nil;


@interface OPhoneNumberFormatter () {
@private
    NSInteger _optionalNestingLevel;
    NSInteger _groupNestingLevel;
    NSArray *_formats;
    
    NSString *_regionIdentifier;
    NSString *_format;
    NSInteger _tokenOffset;
    NSInteger _canonicalOffset;
    NSString *_canonicalisedNumber;
    
    BOOL _isCompleteMatch;
}

@end


@implementation OPhoneNumberFormatter

#pragma mark - Auxiliary methods

- (void)loadCountryCallingCodeToRegionIdentifierMappings
{
    _regionIdentifiersByCountryCallingCode = [NSMutableDictionary dictionary];
    
    NSArray *mappings = [kRegionIdentifiersByCountryCallingCode componentsSeparatedByString:kSeparatorList];
    
    for (NSString *mapping in mappings) {
        NSArray *keyAndValues = [mapping componentsSeparatedByString:kSeparatorMapping];
        
        _regionIdentifiersByCountryCallingCode[keyAndValues[0]] = [keyAndValues[1] componentsSeparatedByString:kSeparatorAlternates];
    }
}


- (void)loadRegionToTemplateMappings
{
    _templatesByRegionIdentifier = [NSMutableDictionary dictionary];
    
    NSArray *mappings = [kTemplatesByRegionCode componentsSeparatedByString:kSeparatorList];
    
    for (NSString *mapping in mappings) {
        NSArray *keysAndValue = [mapping componentsSeparatedByString:kSeparatorMapping];
        NSArray *regionIdentifiers = [keysAndValue[0] componentsSeparatedByString:kSeparatorAlternates];
        
        for (NSString *regionIdentifier in regionIdentifiers) {
            _templatesByRegionIdentifier[regionIdentifier] = keysAndValue[1];
        }
    }
    
    _supportedRegionIdentifiers = [_templatesByRegionIdentifier allKeys];
}


#pragma mark - Parsing templates into formats

- (NSMutableArray *)flattenFormats:(NSMutableArray *)formats
{
    NSMutableArray *flattenedFormats = [NSMutableArray array];
    
    for (id format in formats) {
        if ([format isKindOfClass:[NSString class]]) {
            [flattenedFormats addObject:format];
        } else {
            [flattenedFormats addObjectsFromArray:[self flattenFormats:format]];
        }
    }
    
    return flattenedFormats;
}


- (NSMutableArray *)leafFormatsFromFormats:(NSMutableArray *)formats
{
    if (([formats count] == 1) && [formats[0] respondsToSelector:@selector(appendFormat:)]) {
        [formats addObject:[NSMutableString stringWithString:formats[0]]];
    }
    
    return [formats lastObject];
}


- (NSMutableArray *)levelFormats:(NSArray *)formats includeLeaves:(BOOL)includedLeaves
{
    NSMutableArray *levelFormats = [NSMutableArray array];
    
    for (NSInteger level = _optionalNestingLevel; level < [formats count]; level++) {
        NSMutableArray *nestedFormats = formats[level];
        
        for (NSInteger groupLevel = 0; groupLevel < _groupNestingLevel; groupLevel++) {
            nestedFormats = [nestedFormats lastObject];
            
            if ((groupLevel == _groupNestingLevel - 1) && includedLeaves) {
                nestedFormats = [self leafFormatsFromFormats:nestedFormats];
            }
        }
        
        [levelFormats addObject:nestedFormats];
    }
    
    return levelFormats;
}


- (void)appendToken:(NSString *)token toFormats:(id)formats
{
    if ([formats respondsToSelector:@selector(appendFormat:)]) {
        if (![token isEqualToString:kTokenCanonical] || ![formats containsString:kTokenCanonical]) {
            [formats appendString:token];
        }
    } else {
        for (id subformats in formats) {
            [self appendToken:token toFormats:subformats];
        }
    }
}


- (NSArray *)formatsFromTemplate:(NSString *)template
{
    // NOTE: Does not work with optional levels inside groups; e.g., {a[b]c|d[e]}
    
    _optionalNestingLevel = 0;
    _groupNestingLevel = 0;
    
    NSMutableArray *formats = [NSMutableArray arrayWithObject:[NSMutableArray arrayWithObject:[NSMutableString string]]];
    
    for (NSInteger i = 0; i < [template length]; i++) {
        NSString *token = [template substringWithRange:NSMakeRange(i, 1)];
        
        if ([kFormatTokens containsString:token]) {
            for (NSMutableArray *levelFormats in [self levelFormats:formats includeLeaves:YES]) {
                [self appendToken:token toFormats:levelFormats];
            }
        } else if ([token isEqualToString:kTokenOptionalBegin]) {
            _optionalNestingLevel++;
            
            if (_optionalNestingLevel == [formats count]) {
                formats[_optionalNestingLevel] = [NSMutableArray arrayWithObject:[NSMutableString stringWithString:formats[_optionalNestingLevel - 1][0]]];
            }
        } else if ([token isEqualToString:kTokenOptionalEnd]) {
            _optionalNestingLevel--;
        } else if ([token isEqualToString:kTokenGroupBegin]) {
            for (NSMutableArray *levelFormats in [self levelFormats:formats includeLeaves:NO]) {
                [levelFormats addObject:[NSMutableArray arrayWithObject:[NSMutableString stringWithString:[levelFormats lastObject]]]];
            }
            
            _groupNestingLevel++;
        } else if ([token isEqualToString:kTokenGroupSeparator]) {
            for (NSMutableArray *levelFormats in [self levelFormats:formats includeLeaves:NO]) {
                [levelFormats addObject:[NSMutableString stringWithString:levelFormats[0]]];
            }
        } else if ([token isEqualToString:kTokenGroupEnd]) {
            for (NSMutableArray *levelFormats in [self levelFormats:formats includeLeaves:NO]) {
                [levelFormats removeObjectAtIndex:0];
            }
            
            _groupNestingLevel--;
            
            if (!_groupNestingLevel) {
                for (NSMutableArray *levelFormats in formats) {
                    [levelFormats removeObjectAtIndex:0];
                }
            }
        }
    }
    
    return [self flattenFormats:formats];
}


- (NSMutableArray *)formatsFromTemplates:(NSString *)templates
{
    NSMutableArray *formats = [NSMutableArray array];
    
    for (NSString *template in [templates componentsSeparatedByString:kSeparatorList]) {
        [formats addObjectsFromArray:[self formatsFromTemplate:template]];
    }
    
    return formats;
}


#pragma mark - Parsing and matching

- (NSString *)nextToken
{
    NSString *token = nil;
    
    if (_tokenOffset < [_format length]) {
        token = [_format substringWithRange:NSMakeRange(_tokenOffset, 1)];
        
        if ([token isEqualToString:kTokenCanonical]) {
            _canonicalOffset = _tokenOffset;
            _tokenOffset++;
            
            token = [self nextToken];
        } else {
            _tokenOffset++;
        }
    }
    
    return token;
}


- (NSString *)matchCharacter:(NSString *)character
{
    NSString *matchedCharacters = nil;
    
    if ([kPrintableCharacters containsString:character]) {
        NSString *token = [self nextToken];
        
        if (token) {
            if ([token isEqualToString:character] && ![kWildcardTokens containsString:token]) {
                matchedCharacters = character;
            } else if ([kWildcardTokens containsString:token]) {
                if ([kWhitespaceCharacters containsString:character]) {
                    if ([token isEqualToString:kTokenWildcardStrict]) {
                        matchedCharacters = [self matchCharacter:character];
                    } else {
                        _tokenOffset -= 1;
                        matchedCharacters = character;
                    }
                } else {
                    _tokenOffset -= 2;
                    matchedCharacters = [self matchCharacter:character];
                }
            } else if ([kWhitespaceCharacters containsString:character]) {
                _tokenOffset--;
                matchedCharacters = [NSString string];
            } else if ([kWhitespaceCharacters containsString:token]) {
                matchedCharacters = [self matchCharacter:character];
                
                if (matchedCharacters) {
                    matchedCharacters = [token stringByAppendingString:matchedCharacters];
                }
            } else if ([kCharacters0_9 containsString:character]) {
                if ([token isEqualToString:kTokenNumberAny]) {
                    matchedCharacters = [kCharacters0_9 containsString:character] ? character : nil;
                } else if ([token isEqualToString:kTokenNumber2_9]) {
                    matchedCharacters = [kCharacters2_9 containsString:character] ? character : nil;
                } else if ([token isEqualToString:character]) {
                    matchedCharacters = character;
                }
            }
        }
    } else {
        matchedCharacters = [NSString string];
    }
    
    return matchedCharacters;
}


- (NSString *)matchPhoneNumber:(NSString *)phoneNumber toFormat:(NSString *)format
{
    _format = format;
    _tokenOffset = 0;
    _canonicalOffset = 0;
    _formattedNumber = [NSString string];
    
    for (NSInteger i = 0; _formattedNumber && (i < [phoneNumber length]); i++) {
        NSString *character = [phoneNumber substringWithRange:NSMakeRange(i, 1)];
        NSString *segment = [self matchCharacter:character];
        
        if (segment) {
            _formattedNumber = [_formattedNumber stringByAppendingString:segment];
        } else {
            _formattedNumber = nil;
        }
    }
    
    _isCompleteMatch = _formattedNumber && (_tokenOffset == [_format length]);
    
    return _formattedNumber;
}


- (void)formatPhoneNumber:(NSString *)phoneNumber
{
    _formattedNumber = nil;
    _canonicalisedNumber = nil;
    _flattenedNumber = [NSString string];
    
    for (NSInteger i = 0; i < [phoneNumber length]; i++) {
        NSString *character = [phoneNumber substringWithRange:NSMakeRange(i, 1)];
        
        if ([kFlattenedPhoneNumberCharacters containsString:character]) {
            _flattenedNumber = [_flattenedNumber stringByAppendingString:character];
        }
    }
    
    for (NSInteger i = 0; !_formattedNumber && (i < [_formats count]); i++) {
        [self matchPhoneNumber:_flattenedNumber toFormat:_formats[i]];
    }

    if (_formattedNumber) {
        if (_isCompleteMatch && [_regionIdentifier isEqualToString:[NSLocale regionIdentifier]]) {
            _canonicalisedNumber = [_formattedNumber substringFromIndex:_canonicalOffset];
        } else {
            _canonicalisedNumber = _formattedNumber;
        }
    } else {
        _formattedNumber = _flattenedNumber;
        _canonicalisedNumber = _flattenedNumber;
    }
}


#pragma mark - Initialisation

- (instancetype)initWithRegionIdentifier:(NSString *)regionIdentifier
{
    self = [super init];
    
    if (self) {
        if (!_formattersByRegionIdentifier) {
            _formattersByRegionIdentifier = [NSMutableDictionary dictionary];
            _internationalFormats = [self formatsFromTemplate:kInternationalTemplate];
            
            [self loadCountryCallingCodeToRegionIdentifierMappings];
            [self loadRegionToTemplateMappings];
        }
        
        if ([_supportedRegionIdentifiers containsObject:regionIdentifier]) {
            _formats = [self formatsFromTemplates:_templatesByRegionIdentifier[regionIdentifier]];
        } else {
            _formats = [self formatsFromTemplates:kTemplateGeneric];
        }
        
        _formattersByRegionIdentifier[regionIdentifier] = self;
        _regionIdentifier = regionIdentifier;
    }
    
    return self;
}


#pragma mark - Factory methods

+ (instancetype)formatterForNumber:(NSString *)phoneNumber
{
    OPhoneNumberFormatter *formatter = nil;
    NSString *regionIdentifier = [NSLocale regionIdentifier];
    
    if (_formattersByRegionIdentifier) {
        formatter = _formattersByRegionIdentifier[regionIdentifier];
    } else {
        formatter = [[self alloc] initWithRegionIdentifier:regionIdentifier];
    }
    
    if ([phoneNumber hasPrefix:kTokenPlus] && ([phoneNumber length] > 1)) {
        NSString *prefixedNumber = nil;
        
        for (NSString *format in _internationalFormats) {
            if (!prefixedNumber) {
                prefixedNumber = [formatter matchPhoneNumber:phoneNumber toFormat:format];
            }
        }
        
        if (prefixedNumber) {
            NSString *countryCallingCode = nil;
            
            for (NSInteger i = 1; !countryCallingCode && (i < [prefixedNumber length]); i++) {
                if ([kWhitespaceCharacters containsCharacter:[prefixedNumber characterAtIndex:i]]) {
                    countryCallingCode = [prefixedNumber substringWithRange:NSMakeRange(1, i - 1)];
                }
            }
            
            if (countryCallingCode) {
                NSArray *eligibleRegionIdentifiers = _regionIdentifiersByCountryCallingCode[countryCallingCode];
                
                if (![eligibleRegionIdentifiers containsObject:regionIdentifier]) {
                    regionIdentifier = eligibleRegionIdentifiers[0];
                }
                
                if ([_supportedRegionIdentifiers containsObject:regionIdentifier]) {
                    formatter = _formattersByRegionIdentifier[regionIdentifier];
                    
                    if (!formatter) {
                        formatter = [[self alloc] initWithRegionIdentifier:regionIdentifier];
                    }
                }
            }
        }
    }
    
    if (phoneNumber) {
        [formatter formatPhoneNumber:phoneNumber];
    }
    
    return formatter;
}


#pragma mark - Complete formatting/canonicalisation

- (NSString *)completelyFormattedNumberCanonicalised:(BOOL)canonicalised
{
    NSString *completelyFormattedNumber = nil;
    
    if (_isCompleteMatch) {
        completelyFormattedNumber = canonicalised ? _canonicalisedNumber : _formattedNumber;
    } else {
        completelyFormattedNumber = _flattenedNumber;
    }
    
    return completelyFormattedNumber;
}

@end
