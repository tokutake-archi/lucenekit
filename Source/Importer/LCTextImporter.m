#include "LCTextImporter.h"
#include "LCDateTools.h"
#include "LCMetadataAttribute.h"

@implementation LCTextImporter
- (BOOL) metadataForFile: (NSString *) path type: (NSString *) type 
			  attributes: (NSMutableDictionary *) attributes
{
	if ([[self types] containsObject: type] == NO) return NO;
	[attributes setObject: path forKey: LCPathAttribute];
	[attributes setObject: [NSString stringWithContentsOfFile: path encoding:NSUTF8StringEncoding error:nil]
				   forKey: LCTextContentAttribute];
	NSFileManager *manager = [NSFileManager defaultManager];
    NSDictionary *attribs = [manager attributesOfItemAtPath:path error:nil];
	NSDate *modificationDate = [attribs objectForKey: NSFileModificationDate];
	if ([modificationDate isEqualToDate: [attributes objectForKey: LCContentModificationDateAttribute]] == NO)
	{
		[attributes setObject: [NSString stringWithCalendarDate: [LCCalendarDate date:modificationDate withCalendarFormat: nil timeZone: nil] resolution: LCResolution_SECOND]
					   forKey: LCContentModificationDateAttribute];
		[attributes setObject: [NSString stringWithCalendarDate: [LCCalendarDate date] resolution: LCResolution_SECOND]
					   forKey: LCMetadataChangeDateAttribute];
		return YES;
	}
	else
		return NO;
}

- (NSArray *) types
{
	return [NSArray arrayWithObjects: @"txt", @"text", nil];
}

- (NSString *) identifier
{
	return LCPathAttribute;
}

@end
