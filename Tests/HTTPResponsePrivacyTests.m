#import <Foundation/Foundation.h>
#import "HttpResponse.h"
#import "Logger.h"

static NSMutableString *captured;
void Log(LogLevel level, NSString *format, ...) {
    va_list args;
    va_start(args, format);
    [captured appendString:[[NSString alloc] initWithFormat:format arguments:args]];
    va_end(args);
}
int main(void) {
    @autoreleasepool {
        captured = [NSMutableString string];
        HttpResponse *response = [HttpResponse new];
        NSString *secret = @"ASTRALIGHT_TEST_SECRET_7f31";
        NSString *xml = [NSString stringWithFormat:@"<root status_code=\"200\" status_message=\"OK\"><pairingsecret>%@</pairingsecret></root>", secret];
        [response populateWithData:[xml dataUsingEncoding:NSUTF8StringEncoding]];
        NSCAssert(response.isStatusOk && [[response getStringTag:@"pairingsecret"] isEqualToString:secret], @"Valid pairing responses must still parse");
        NSCAssert(![captured containsString:secret], @"Pairing payload leaked through app logging");
        [captured setString:@""];
        NSString *invalid = [NSString stringWithFormat:@"<root><pairingsecret>%@</broken>", secret];
        [response populateWithData:[invalid dataUsingEncoding:NSUTF8StringEncoding]];
        NSCAssert(![captured containsString:secret], @"Malformed payload leaked through app logging");
        puts("PASS HTTP response privacy: valid and malformed pairing payloads");
    }
    return 0;
}
