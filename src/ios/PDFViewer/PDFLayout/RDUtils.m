//
//  RDUtils.m
//  RadaeePDF-Cordova
//
//  Created by Emanuele Bortolami on 26/09/17.
//

#import "RDUtils.h"
#import <CommonCrypto/CommonDigest.h>

//Open pdf file from filestream
@implementation PDFFileStream

-(void)open :(NSString *)filePath
{
    //fileHandle = [NSFileHandle fileHandleForReadingAtPath:testfile];
    const char *path = [filePath UTF8String];
    if((m_file = fopen(path, "rb+"))){
        m_writable = true;
    }
    else {
        m_file = fopen(path,"rb");
        m_writable = false;
    }
}
-(bool)writeable
{
    return m_writable;
}
-(void)close :(NSString *)filePath
{
    if( m_file )
        fclose(m_file);
    m_file = NULL;
}
-(int)read: (void *)buf : (int)len
{
    if( !m_file ) return 0;
    int read = (int)fread(buf, 1, len,m_file);
    return read;
}
-(int)write:(const void *)buf :(int)len
{
    if( !m_file ) return 0;
    return (int)fwrite(buf, 1, len, m_file);
}

-(unsigned long long)position
{
    if( !m_file ) return 0;
    int pos = (int)ftell(m_file);
    return pos;
}

-(unsigned long long)length
{
    if( !m_file ) return 0;
    int pos = (int)ftell(m_file);
    fseek(m_file, 0, SEEK_END);
    int filesize = (int)ftell(m_file);
    fseek(m_file, pos, SEEK_SET);
    return filesize;
}

-(bool)seek:(unsigned long long)pos
{
    if( !m_file ) return false;
    fseek(m_file, (int)pos , SEEK_SET);
    return true;
}
@end

@implementation RDFileItem
-(id)init:(NSString *)help :(NSString *)path :(int)level
{
    self = [super init];
    if(self)
    {
        _help = help;
        _path = path;
        _level = level;
        _locker = [[RDVLocker alloc] init];
    }
    return self;
}
@end

@implementation NSData (Radaee)

- (NSString *)MD5
{
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5([self bytes], 32, md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    {
        [output appendFormat:@"%02x",md5Buffer[i]];
    }
    
    return output;
}

@end

@implementation NSString (Radaee)

- (NSString *)MD5
{
    // Create pointer to the string as UTF8
    const char *ptr = [self UTF8String];
    
    // Create byte array of unsigned chars
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    // Create 16 byte MD5 hash value, store in buffer
    CC_MD5(ptr, (int)strlen(ptr), md5Buffer);
    
    // Convert MD5 value in the buffer to NSString of hex values
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x",md5Buffer[i]];
    
    return output;
}

@end

@implementation RDUtils

#pragma mark - Utils

+ (NSString *)getPDFID:(NSString *)pdfPath password:(NSString *)password
{
    RDPDFDoc *m_doc = [[RDPDFDoc alloc] init];
    if ([m_doc open:pdfPath :password] == 0) {
        return [RDUtils getPDFIDForDoc:m_doc];
    }
    
    return @"";
}

+ (NSString *)getPDFIDForDoc:(RDPDFDoc *)m_doc
{
    if (m_doc) {
        
        NSString *pdfid = [RDUtils getTagId:m_doc];
        
        if (pdfid.length > 0) {
            return pdfid;
        }
        
        unsigned char *pConstChar = malloc(32);
        [m_doc PDFID:pConstChar];
        NSData *data = [NSData dataWithBytes:pConstChar length:32];
        NSLog(@"%@", [data MD5]);
        pdfid = [data MD5];
        
        [RDUtils setTagId:pdfid doc:m_doc];
        
        m_doc = nil;
        free(pConstChar);
        
        return pdfid;
    }
    
    return @"";
}

+ (NSString *)getTagId:(RDPDFDoc *)m_doc
{
    if (m_doc) {
        return [m_doc meta:UUID];
    }
    
    return @"";
}

+ (void)setTagId:(NSString *)tag doc:(RDPDFDoc *)m_doc
{
    if (m_doc) {
        [m_doc setMeta:UUID :tag];
    }
}

+ (NSDate *)dateFromPdfDate:(NSString *)dateString
{
    if (!dateString || dateString.length == 0) {
        return nil;
    }
    // Remove "D:"
    dateString = [dateString stringByReplacingOccurrencesOfString:@"D:" withString:@""];
    
    // Replace "'" with ":"
    dateString = [dateString stringByReplacingOccurrencesOfString:@"'" withString:@":"];
    
    // Remove the last "'"
    dateString = [dateString substringToIndex:(dateString.length - 1)];
    
    // Convert string to date object
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMddHHmmssZ"];
    NSDate *date = [dateFormat dateFromString:dateString];
    
    return date;
}

+ (NSString *)pdfDateFromDate:(NSDate *)date
{
    // Convert date object to desired output format
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyyMMddHHmmssZZZZZ"];
    NSString* dateString = [dateFormat stringFromDate:date];
    
    dateString = [@"D:" stringByAppendingString:[[dateString stringByReplacingOccurrencesOfString:@":" withString:@"'"] stringByAppendingString:@"'"]];
    
    return dateString;
}

+ (UIColor *)invertColor:(UIColor *)color {
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    return [UIColor colorWithRed:1.-r green:1.-g blue:1.-b alpha:a];
}

+ (id)getGlobalFromString:(NSString *)string
{
    id global = [GLOBAL valueForKey:string];
    return global;
}

+ (void)setGlobalFromString:(NSString *)string withValue:(id)value
{
    [GLOBAL setValue:value forKey:string];
}

+ (UIColor *)radaeeWhiteColor
{
    if (@available(iOS 11.0, *)) {
        return [UIColor colorNamed:@"systemWhiteColor"];
    }
    return [UIColor whiteColor];
}

+ (UIColor *)radaeeBlackColor
{
    if (@available(iOS 11.0, *)) {
        return [UIColor colorNamed:@"systemBlackColor"];
    }
    return [UIColor blackColor];
}

+ (UIColor *)radaeeIconColor {
    if (@available(iOS 11.0, *)) {
        return [UIColor colorNamed:@"iconTint"];
    }
    return [UIColor orangeColor];
}

@end
