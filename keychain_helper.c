#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <stdio.h>

// Compile with: gcc -o keychain_helper keychain_helper.c -framework Security -framework CoreFoundation

int main(int argc, char *argv[]) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <service>\n", argv[0]);
        return 1;
    }

    const char *serviceName = argv[1];
    CFStringRef service = CFStringCreateWithCString(NULL, serviceName, kCFStringEncodingUTF8);

    const void *keys[] = { kSecClass, kSecAttrService, kSecReturnAttributes, kSecMatchLimit };
    const void *values[] = { kSecClassGenericPassword, service, kCFBooleanTrue, kSecMatchLimitAll };
    
    CFDictionaryRef query = CFDictionaryCreate(NULL, keys, values, 4, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching(query, &result);

    if (status == errSecSuccess) {
        if (CFGetTypeID(result) == CFArrayGetTypeID()) {
            CFArrayRef items = (CFArrayRef)result;
            CFIndex count = CFArrayGetCount(items);
            for (CFIndex i = 0; i < count; i++) {
                CFDictionaryRef item = (CFDictionaryRef)CFArrayGetValueAtIndex(items, i);
                CFStringRef account = (CFStringRef)CFDictionaryGetValue(item, kSecAttrAccount);
                
                if (account) {
                    char buffer[256];
                    if (CFStringGetCString(account, buffer, sizeof(buffer), kCFStringEncodingUTF8)) {
                        printf("%s\n", buffer);
                    }
                }
            }
        } else if (CFGetTypeID(result) == CFDictionaryGetTypeID()) {
            // Single item found
            CFDictionaryRef item = (CFDictionaryRef)result;
            CFStringRef account = (CFStringRef)CFDictionaryGetValue(item, kSecAttrAccount);
            if (account) {
                char buffer[256];
                if (CFStringGetCString(account, buffer, sizeof(buffer), kCFStringEncodingUTF8)) {
                    printf("%s\n", buffer);
                }
            }
        }
    } else if (status == errSecItemNotFound) {
        // No items, print nothing
    } else {
        fprintf(stderr, "Error: %d\n", (int)status);
    }

    if (result) CFRelease(result);
    CFRelease(query);
    CFRelease(service);

    return 0;
}
