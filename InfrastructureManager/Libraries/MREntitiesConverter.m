#import "MREntitiesConverter.h"

@implementation MREntitiesConverter

- (id)init
{
        return [super init];
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)s
{
        [resultString appendString:s];
}

- (NSString*)convertEntiesInString:(NSString*)s
{
        if (s == nil)
                return nil;

        resultString = [[NSMutableString alloc] init];

        NSString *xmlStr = [NSString stringWithFormat:@"<d>%@</d>", s];
        NSData *data = [xmlStr dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        [parser setDelegate:self];
        [parser parse];
        [parser release];

        return [resultString autorelease];
}

- (void)dealloc
{
        [super dealloc];
}

@end
