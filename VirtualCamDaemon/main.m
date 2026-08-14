#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <unistd.h>

#define STATUS_FILE @"/tmp/virtualcam_active"
#define FRAME_FILE @"/tmp/virtualcam_frame.jpg"
#define PORT 2345

void handleClient(int clientSocket) {
    while (1) {
        uint32_t len = 0;
        ssize_t bytesRead = recv(clientSocket, &len, sizeof(len), 0);
        if (bytesRead <= 0) break;
        
        len = CFSwapInt32LittleToHost(len); // LE length
        if (len > 10 * 1024 * 1024) break; // sanity check 10MB
        
        NSMutableData *data = [NSMutableData dataWithCapacity:len];
        uint32_t remaining = len;
        
        while (remaining > 0) {
            char buffer[8192];
            size_t toRead = MIN(remaining, sizeof(buffer));
            ssize_t r = recv(clientSocket, buffer, toRead, 0);
            if (r <= 0) break;
            [data appendBytes:buffer length:r];
            remaining -= r;
        }
        
        if (remaining > 0) break; // Error reading
        
        NSError *error = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (error || !json) continue;
        
        NSString *cmd = json[@"cmd"];
        if ([cmd isEqualToString:@"PING"]) {
            NSDictionary *pong = @{@"cmd": @"PONG"};
            NSData *pongData = [NSJSONSerialization dataWithJSONObject:pong options:0 error:nil];
            uint32_t pongLen = CFSwapInt32HostToLittle((uint32_t)pongData.length);
            send(clientSocket, &pongLen, sizeof(pongLen), 0);
            send(clientSocket, pongData.bytes, pongData.length, 0);
        }
        else if ([cmd isEqualToString:@"SHOW_MENU"]) {
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.virtualcam.showmenu"), NULL, NULL, true);
        }
        else if ([cmd isEqualToString:@"PLAY"]) {
            [@"1" writeToFile:STATUS_FILE atomically:YES encoding:NSUTF8StringEncoding error:nil];
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.virtualcam.play"), NULL, NULL, true);
        }
        else if ([cmd isEqualToString:@"STOP"]) {
            unlink([STATUS_FILE UTF8String]);
            CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.virtualcam.stop"), NULL, NULL, true);
        }
        else if ([cmd isEqualToString:@"FRAME"]) {
            NSString *b64 = json[@"data"];
            if (b64) {
                NSData *jpegData = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
                if (jpegData) {
                    [jpegData writeToFile:FRAME_FILE atomically:YES];
                    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.virtualcam.newframe"), NULL, NULL, true);
                }
            }
        }
    }
    
    close(clientSocket);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSLog(@"[VirtualCamDaemon] Starting...");
        
        unlink([STATUS_FILE UTF8String]);
        
        int serverSocket = socket(AF_INET, SOCK_STREAM, 0);
        if (serverSocket < 0) {
            NSLog(@"[VirtualCamDaemon] Failed to create socket");
            return 1;
        }
        
        int opt = 1;
        setsockopt(serverSocket, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));
        
        struct sockaddr_in serverAddr;
        memset(&serverAddr, 0, sizeof(serverAddr));
        serverAddr.sin_family = AF_INET;
        serverAddr.sin_addr.s_addr = INADDR_ANY;
        serverAddr.sin_port = htons(PORT);
        
        if (bind(serverSocket, (struct sockaddr *)&serverAddr, sizeof(serverAddr)) < 0) {
            NSLog(@"[VirtualCamDaemon] Bind failed");
            return 1;
        }
        
        if (listen(serverSocket, 5) < 0) {
            NSLog(@"[VirtualCamDaemon] Listen failed");
            return 1;
        }
        
        NSLog(@"[VirtualCamDaemon] Listening on port %d", PORT);
        
        while (1) {
            struct sockaddr_in clientAddr;
            socklen_t clientLen = sizeof(clientAddr);
            int clientSocket = accept(serverSocket, (struct sockaddr *)&clientAddr, &clientLen);
            
            if (clientSocket < 0) {
                NSLog(@"[VirtualCamDaemon] Accept failed");
                continue;
            }
            
            NSLog(@"[VirtualCamDaemon] Client connected");
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                handleClient(clientSocket);
                NSLog(@"[VirtualCamDaemon] Client disconnected");
            });
        }
    }
    return 0;
}
