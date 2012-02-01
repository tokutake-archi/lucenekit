#import "AppDelegate.h"

static NSString *FIELD_TEXT = @"T";
static NSString *FIELD_PATH = @"P";

@implementation AppDelegate

@synthesize window;
@synthesize searchBar;
@synthesize resultField;

- (void) fillDirectory:(LCFSDirectory*) rd
{
    LCSimpleAnalyzer *analyzer = [[LCSimpleAnalyzer alloc] init];
    
    LCIndexWriter *writer = [[LCIndexWriter alloc] initWithDirectory: rd
                                                            analyzer: analyzer
                                                              create: YES];
    
    int i = 0;
    const int BUFFER_SIZE = 1024 * 512;
    char buffer[BUFFER_SIZE];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"data" ofType:@"txt"]; 
    
    NSLog(@"opening %@", filePath);
    
    FILE *fh = fopen([filePath cStringUsingEncoding:NSASCIIStringEncoding], "r");
    
    if (fh) while(!feof(fh)) {
        
        if (fgets(buffer, BUFFER_SIZE, fh) == NULL) {
            NSLog(@"no further line");
            break;
        }
        
        NSLog(@"* %d", i);
        
        NSString *line = [[NSString alloc] initWithCString:buffer encoding:NSUTF8StringEncoding];

        LCDocument *document = [[LCDocument alloc] init];


        LCField *f1 = [[LCField alloc] initWithName: FIELD_TEXT
                                            string: line
                                             store: LCStore_NO
                                             index: LCIndex_Tokenized];                                         

        LCField *f2 = [[LCField alloc] initWithName: FIELD_PATH
                                   string: [NSString stringWithFormat:@"some/path/to/%d", i]
                                    store: LCStore_YES
                                    index: LCIndex_NO];
        [document addField: f1];
        [document addField: f2];

        [f1 release];
        [f2 release];

        [writer addDocument: document];

        [document release];
        
        [line release];

        i++;
    }

    fclose(fh);

    NSLog(@"closing writer");

    [writer close];    
    [writer release];

    [analyzer release];
}

- (LCFSDirectory*) createFileDirectory
{
    NSString *supportPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];

    NSString *path = [supportPath stringByAppendingPathComponent:@"index.idx"];

    if ([[NSFileManager defaultManager] isReadableFileAtPath:path]) {
        return [[LCFSDirectory alloc] initWithPath:path create: YES];
    }

    LCFSDirectory *rd = [[LCFSDirectory alloc] initWithPath:path create: YES];

    [self fillDirectory:rd];
    
    return rd;
}

- (LCFSDirectory*) createRamDirectory
{
    LCFSDirectory *rd = (LCFSDirectory *)[[LCRAMDirectory alloc] init];

    [self fillDirectory:rd];
    
    return rd;
}


- (void)applicationDidFinishLaunching:(UIApplication *)application {    

    [window makeKeyAndVisible];

    LCFSDirectory *rd = [self createFileDirectory];

    NSLog(@"opening searcher");

	searcher = [[LCIndexSearcher alloc] initWithDirectory: rd];

    [rd release];

    NSLog(@"ready");
    
    [resultField setText:@""];

}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSLog(@"searching %@", searchText);

    LCTerm *t = [[LCTerm alloc] initWithField: FIELD_TEXT text: searchText];

    LCTermQuery *tq = [[LCTermQuery alloc] initWithTerm: t];

    LCHits *hits = [searcher search: tq];

    LCHitIterator *iterator = [hits iterator];
    
    while([iterator hasNext]) {
        LCHit *hit = [iterator next];
        
        NSString *path = [hit stringForField: FIELD_PATH];
        NSLog(@"%@ -> %@", hit, path);
    }

    int results = [hits count];

    [resultField setText:[NSString stringWithFormat:@"%d", results]];

}

- (void)dealloc {
    [searcher release];
    [window release];
    [searchBar release];
    [super dealloc];
}


@end
