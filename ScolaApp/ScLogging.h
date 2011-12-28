//
//  ScLogging.h
//  ScolaApp
//
//  Created by Anders Blehr on 06.11.11.
//  Copyright (c) 2011 Rhelba Software. All rights reserved.
//

#ifndef ScolaApp_ScLogging_h
#define ScolaApp_ScLogging_h

#define TRC_LEVEL_ALL 5
#define TRC_LEVEL_DBG 4
#define TRC_LEVEL_INF 3
#define TRC_LEVEL_WRN 2
#define TRC_LEVEL_ERR 1
#define TRC_LEVEL_BRK 0

#ifndef TRC_LEVEL
#if TARGET_IPHONE_SIMULATOR != 0
#define TRC_LEVEL TRC_LEVEL_DBG
#else
#define TRC_LEVEL TRC_LEVEL_DBG
#endif
#endif

/*****************************************************************************/
/* Loggin macros for various log levels                                      */
/*****************************************************************************/
#if TRC_LEVEL >= 5
#define ScLogEntry NSLog(@"ENTRY: %s", __PRETTY_FUNCTION__)
#define ScLogExit NSLog(@"EXIT: %s", __PRETTY_FUNCTION__)
#else
#define ScLogEntry
#define ScLogExit
#endif

#if (TRC_LEVEL >= 4)
#define ScLogDebug(A, ...) NSLog(@"DEBUG: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define ScLogDebug(A, ...)
#endif

#if (TRC_LEVEL >= 3)
#define ScLogInfo(A, ...) NSLog(@"INFO: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define ScLogInfo(A, ...)
#endif

#if (TRC_LEVEL >= 2)
#define ScLogWarning(A, ...) NSLog(@"WARNING: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define ScLogWarning(A, ...)
#endif

#if (TRC_LEVEL >= 1)
#define ScLogError(A, ...) NSLog(@"ERROR: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define ScLogError(A, ...)
#endif

#if (TRC_LEVEL >= 0)
#define ScLogBreakage(A, ...) NSLog(@"BROKEN: %s[%d]: %@", __PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:A, ## __VA_ARGS__])
#else
#define ScLogError(A, ...)
#endif

#endif
