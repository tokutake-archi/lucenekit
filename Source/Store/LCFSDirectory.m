#include "LCFSDirectory.h"
#include "LCFSIndexInput.h"
#include "LCFSIndexOutput.h"
#include "GNUstep.h"

/**
* Straightforward implementation of {@link Directory} as a directory of files.
 * <p>If the system property 'disableLuceneLocks' has the String value of
 * "true", lock creation will be disabled.
 *
 * @see Directory
 * @author Doug Cutting
 */
@implementation LCFSDirectory

+ (LCFSDirectory *) directoryAtPath: (NSString *) absolutePath
						  create: (BOOL) create
{
	LCFSDirectory *dir = [[LCFSDirectory alloc] initWithPath: absolutePath
													  create: create];
	return AUTORELEASE(dir);
}

- (BOOL) create // Create new directory, remove existed
{
	NSArray *paths = [path pathComponents];
	NSString *p = nil;
	BOOL isDir;
	int i, count = [paths count];
	ASSIGN(p, [NSString string]);
	
	for(i = 0; i < count; i++)
    {
		ASSIGN(p, [p stringByAppendingPathComponent: [paths objectAtIndex: i]]);
		if ([manager fileExistsAtPath: p isDirectory: &isDir])
        {
			if (isDir == NO)
			{
				NSLog(@"Error: Not a directory %@", p);
				// Very dangerous !!
				//[manager removeFileAtPath: p handle: nil];
				DESTROY(p);
				return NO;
			}
        }
		else
        {
            [manager createDirectoryAtPath:p withIntermediateDirectories:NO attributes:nil error:nil];
		}
    }
	
	DESTROY(p);
	return YES;
}

- (id) initWithPath: (NSString *) paramPath create: (BOOL) create
{
	BOOL isDir;
	self = [self init];
	ASSIGN(manager, [NSFileManager defaultManager]);
	ASSIGNCOPY(path, paramPath);
	if (create) {
		if ([self create] == NO) {	
			NSLog(@"Unable to create directory");
			DESTROY(manager);
			DESTROY(path);
			return nil;
		}
    }
	if (!([manager fileExistsAtPath: path isDirectory: &isDir] && isDir)) {
		NSLog(@"Not a directory");
		DESTROY(manager);
		DESTROY(path);
		return nil;
    }
	return self;
}

- (void) dealloc
{
	DESTROY(manager);
	DESTROY(path);
	[super dealloc];
}

/** Returns an array of strings, one for each file in the directory. */
- (NSArray *) fileList
{
    return [manager contentsOfDirectoryAtPath:path error:nil];
}

/** Returns true iff a file with the given name exists. */
- (BOOL) fileExists: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
	return [manager fileExistsAtPath: p];
}

/** Returns the time the named file was last modified. */
- (NSTimeInterval) fileModified: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
    NSDictionary *d = [manager attributesOfItemAtPath:p error:nil];
	return [[d objectForKey: NSFileModificationDate] timeIntervalSince1970];
}

/** Set the modified time of an existing file to now. */
- (void) touchFile: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
    NSDictionary *d = [manager attributesOfItemAtPath:p error:nil];
	NSMutableDictionary *n = [NSMutableDictionary dictionaryWithDictionary: d];
	[n setObject: [NSDate date] forKey: NSFileModificationDate];
    [manager setAttributes:n ofItemAtPath:p error:nil];
}

/** Returns the length in bytes of a file in the directory. */
- (unsigned long long) fileLength: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
    NSDictionary *d = [manager attributesOfItemAtPath:p error:nil];
	return [[d objectForKey: NSFileSize] unsignedLongLongValue];
}

/** Removes an existing file in the directory. */
- (BOOL) deleteFile: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
    if ([manager fileExistsAtPath: p] == YES)
    {
        if ([manager removeItemAtPath:p error:nil] == NO)
    	{
            NSLog(@"Cannot remove file %@", p);
            return NO;
        }
    }
	return YES;
}

/** Renames an existing file in the directory. */
- (void) renameFile: (NSString *) from to: (NSString *) to
{
	NSString *old, *nu;
	old = [path stringByAppendingPathComponent: from];
	nu = [path stringByAppendingPathComponent: to];
	
	if ([manager fileExistsAtPath: old] == NO)
    {
		return;
    }
	if ([manager fileExistsAtPath: nu] == YES)
    {
        if ([manager removeItemAtPath:nu error:nil] == NO)
        {
			NSLog(@"Cannot remove %@", nu);
			return;
		}
    }
	
    [manager moveItemAtPath:old toPath:nu error:nil];
}

/** Creates a new, empty file in the directory with the given name.
Returns a stream writing this file. */
- (LCIndexOutput *) createOutput: (NSString *) name
{
//FIXME: should delete old file and create new one.
/*  File file = new File(directory, name);
 	     if (file.exists() && !file.delete())          // delete existing, if any
	      	       throw new IOException("Cannot overwrite: " + file);
		       */
	NSString *p = [path stringByAppendingPathComponent: name];
	LCFSIndexOutput *output = [[LCFSIndexOutput alloc] initWithFile: p];
	return AUTORELEASE(output);
}

/** Returns a stream reading an existing file. */
- (LCIndexInput *) openInput: (NSString *) name
{
	NSString *p = [path stringByAppendingPathComponent: name];
       if ([manager fileExistsAtPath: p] == YES)
       {
	  LCFSIndexInput *input = [[LCFSIndexInput alloc] initWithFile: p];
	  return AUTORELEASE(input);
       }
       else
       {
          NSLog(@"File %@ does not exist", p);
	  return nil;
       }
}

/** Closes the store to future operations. */
- (void) close
{
}

/** For debug output. */
- (NSString *) description
{
	return [NSString stringWithFormat: @"%@@%@", NSStringFromClass([self class]), path];
}

@end
