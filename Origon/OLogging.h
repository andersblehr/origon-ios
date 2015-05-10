//
//  OLogging.h
//  Origon
//
//  Created by Anders Blehr on 17.10.12.
//  Copyright (c) 2012 Rhelba Source. All rights reserved.
//

#ifndef Origon_OLogging_h
#define Origon_OLogging_h

#define TRC_LEVEL_ALL 5
#define TRC_LEVEL_DBG 4
#define TRC_LEVEL_INF 3
#define TRC_LEVEL_WRN 2
#define TRC_LEVEL_ERR 1
#define TRC_LEVEL_BRK 0
#define TRC_LEVEL_NONE -1

#ifndef TRC_LEVEL
#if TARGET_IPHONE_SIMULATOR != 0
#define TRC_LEVEL TRC_LEVEL_DBG
#else
#define TRC_LEVEL TRC_LEVEL_NONE
#endif
#endif

/*****************************************************************************/
/* Logging macros for various log levels                                      */
/*****************************************************************************/
#if TRC_LEVEL >= TRC_LEVEL_ALL
#define OLogEntry NSLog(@"ENTRY: %s", __PRETTY_FUNCTION__)
#define OLogExit NSLog(@"EXIT: %s", __PRETTY_FUNCTION__)
#define OLogVerbose(A, ...) NSLog(@"VERBOSE: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogEntry
#define OLogExit
#define OLogVerbose(A, ...)
#endif

#if (TRC_LEVEL >= TRC_LEVEL_DBG)
#define OLogState NSLog(@"STATE: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [[OState s] asString])
#define OLogDebug(A, ...) NSLog(@"DEBUG: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogState
#define OLogDebug(A, ...)
#endif

#if (TRC_LEVEL >= TRC_LEVEL_INF)
#define OLogInfo(A, ...) NSLog(@"INFO: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogInfo(A, ...)
#endif

#if (TRC_LEVEL >= TRC_LEVEL_WRN)
#define OLogWarning(A, ...) NSLog(@"WARNING: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogWarning(A, ...)
#endif

#if (TRC_LEVEL >= TRC_LEVEL_ERR)
#define OLogError(A, ...) NSLog(@"ERROR: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogError(A, ...)
#endif

#if (TRC_LEVEL >= TRC_LEVEL_BRK)
#define OLogBreakage(A, ...) NSLog(@"BROKEN: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define OLogBreakage(A, ...)
#endif

#endif
