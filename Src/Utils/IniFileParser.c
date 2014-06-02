#include <stdio.h> 
#include <string.h> 
#include <stdlib.h>
#include <ctype.h>

#include "unzip.h"
#include "IniFileParser.h"


// PacketFileSystem.h Need to be included after all other includes
#include "PacketFileSystem.h"

struct IniFile
{
    char *iniBuffer;
    char *iniPtr;
    char *iniEnd;
    char *wrtBuffer;
    int   wrtBufferSize;
    int   wrtOffset;
    int   modified;
    char  iniFilename[512];
    char  zipFile[512];
    int   isZipped;
};

static int readFile(IniFile *iniFile)
{
    int length;
    int success = 0;
    
    if (!iniFile->isZipped)
    {
        // File is not compressed
        FILE* f = fopen(iniFile->iniFilename, "r");
        if (f != NULL)
        {
            fseek(f, 0, SEEK_END);
            length = ftell(f);
            fseek(f, 0, SEEK_SET);

            if (length > 0) {
                iniFile->iniBuffer = malloc(length);
                length = fread(iniFile->iniBuffer, 1, length, f);
                if (length > 0) {
                    iniFile->iniPtr = iniFile->iniBuffer;
                    iniFile->iniEnd = iniFile->iniBuffer + length;
                }
                else {
                    free(iniFile->iniBuffer);
                    iniFile->iniBuffer = NULL;
                }
            }
            fclose(f);
            
            success = 1;
        }
    }
    else
    {
        // File is compressed
        unzFile zip;
        unz_file_info info;
        
        zip = unzOpen(iniFile->zipFile);
        if (zip)
        {
            int err = unzGoToFirstFile(zip);
            int fileFound = 0;
            char szCurrentFileName[256 + 1];
            
            while (err == UNZ_OK)
            {
                char *compressedFileName;
                
                err = unzGetCurrentFileInfo(zip, NULL,
                                            szCurrentFileName, sizeof(szCurrentFileName) - 1,
                                            NULL, 0, NULL, 0);
                
                compressedFileName = strrchr(szCurrentFileName, '/');
                if (compressedFileName == NULL)
                    compressedFileName = strrchr(szCurrentFileName, '\\');
                
                if (compressedFileName == NULL)
                    compressedFileName = szCurrentFileName;
                else
                    compressedFileName++;
                
                if (err == UNZ_OK)
                {
                    if (unzStringFileNameCompare(iniFile->iniFilename, compressedFileName, 1) == 0)
                    {
                        fileFound = 1;
                        break;
                    }
                    
                    err = unzGoToNextFile(zip);
                }
            }
            
            if (fileFound)
            {
                // Re-set the ini filename to the full path inside the compressed archive
                strcpy(iniFile->iniFilename, szCurrentFileName);
                
                if (unzOpenCurrentFile(zip) == UNZ_OK)
                {
                    unzGetCurrentFileInfo(zip, &info,NULL,0,NULL,0,NULL,0);
                    
                    length = info.uncompressed_size;
                    if (length > 0)
                    {
                        iniFile->iniBuffer = malloc(length);
                        if (iniFile->iniBuffer)
                        {
                            unzReadCurrentFile(zip, iniFile->iniBuffer, length);
                            
                            iniFile->iniPtr = iniFile->iniBuffer;
                            iniFile->iniEnd = iniFile->iniBuffer + length;
                            
                            success = 1;
                        }
                    }
                    
                    unzCloseCurrentFile(zip);
                    success = 1;
                }
            }
            
            unzClose(zip);
        }
    }
    
    return success;
}

static int readLine(IniFile *iniFile, char *line)
{   
    int i = 0; 

    while (iniFile->iniPtr != iniFile->iniEnd) {
        char c = *iniFile->iniPtr++;
        if (c == '\r') {
            continue;
        }
        if (c == '\n') {
            *line = 0;
            return i;
        }
        *line++ = c; 
        i++;
    }

    return -1;
}

static void createWriteBuffer(IniFile *iniFile)
{
    iniFile->wrtBufferSize = 8192;
    iniFile->wrtBuffer = malloc(iniFile->wrtBufferSize);
    iniFile->wrtOffset = 0;
}

static void rewindBuffer(IniFile *iniFile)
{
    iniFile->iniPtr = iniFile->iniBuffer;
}

static void destroyWriteBuffer(IniFile *iniFile)
{
    if (iniFile->iniBuffer) {
        free(iniFile->iniBuffer);
    }
    iniFile->iniBuffer = iniFile->wrtBuffer;
    iniFile->iniPtr = iniFile->iniBuffer;
    iniFile->iniEnd = iniFile->iniBuffer + iniFile->wrtOffset;
}

static void writeLine(IniFile *iniFile, const char* line)
{
    int length = strlen(line);
    if (length + iniFile->wrtOffset > iniFile->wrtBufferSize) {
        iniFile->wrtBufferSize += 8192;
        iniFile->wrtBuffer = realloc(iniFile->wrtBuffer, iniFile->wrtBufferSize);
    }

    memcpy(iniFile->wrtBuffer + iniFile->wrtOffset, line, length);
    iniFile->wrtOffset += length;

    iniFile->modified = 1;
}

static void writeFile(IniFile *iniFile, const char* filename)
{
    FILE* f = fopen(filename, "w");
    if (f == NULL) {
        return;
    }
    fwrite(iniFile->iniBuffer, 1, iniFile->iniEnd - iniFile->iniBuffer, f);
    fclose(f);
}

IniFile *iniFileOpen(const char *filename)
{
    IniFile *iniFile = (IniFile *)malloc(sizeof(IniFile));
    
    if (iniFile != NULL)
    {
        iniFile->isZipped = 0;
        iniFile->isZipped = NULL;
        
        iniFile->modified = 0;
        
        iniFile->iniPtr = NULL;
        iniFile->iniEnd = NULL;
        iniFile->iniBuffer = NULL;
        
        strcpy(iniFile->iniFilename, filename);
        readFile(iniFile);
    }
    
    return iniFile;
}

IniFile *iniFileOpenZipped(const char *zipFile, const char *iniFilename)
{
    IniFile *iniFile = (IniFile *)malloc(sizeof(IniFile));
    
    if (iniFile != NULL)
    {
        iniFile->isZipped = 1;
        iniFile->modified = 0;
        
        iniFile->iniPtr = NULL;
        iniFile->iniEnd = NULL;
        iniFile->iniBuffer = NULL;
        
        strcpy(iniFile->iniFilename, iniFilename);
        strcpy(iniFile->zipFile, zipFile);
        
        readFile(iniFile);
    }
    
    return iniFile;
}

int iniFileClose(IniFile *iniFile)
{
    if (iniFile->iniBuffer == NULL) {
        return 0;
    }

    if (iniFile->modified) {
        writeFile(iniFile, iniFile->iniFilename);
    }

    free(iniFile->iniBuffer);
    iniFile->iniBuffer = NULL;

    return 1;
}

const char *iniFileGetFilePath(IniFile *iniFile)
{
    return iniFile->iniFilename;
}

int iniFileGetInt(IniFile *iniFile,
                  char* section,
                  char* entry, 
                  int   def) 
{   

    char buff[MAX_LINE_LENGTH]; 
    char *ep; 
    char t_section[MAX_LINE_LENGTH]; 
    char value[6]; 
    int len = strlen(entry); 
    int i; 
    
    rewindBuffer(iniFile);

    sprintf(t_section, "[%s]", section);

    do {   
        if (readLine(iniFile, buff) < 0) {
            return def; 
        } 
    } while(strcmp(buff, t_section)); 

    do {   
        if (readLine(iniFile, buff) < 0 || buff[0] == '[') {
            return def; 
        } 
    } while(strncmp(buff, entry, len)); 

    ep = strrchr(buff, '=');
    if (ep == NULL) {
        return def;
    }
    ep++;
    if (!strlen(ep)) {
        return def; 
    }

    for (i = 0; isdigit(ep[i]); i++) {
        value[i] = ep[i]; 
    }

    value[i] = '\0'; 
    
    return atoi(value); 


} 


int iniFileGetString(IniFile *iniFile,
                     char* section,
                     char* entry, 
                     char* defVal, 
                     char* buffer, 
                     int   bufferLen) 
{   
    char def[MAX_LINE_LENGTH];
    char buff[MAX_LINE_LENGTH]; 
    char *ep; 
    char t_section[MAX_LINE_LENGTH]; 
    int len = strlen(entry); 

    rewindBuffer(iniFile);

    strcpy(def, defVal);

    sprintf(t_section, "[%s]", section);
     
    do {   
        if (readLine(iniFile, buff) < 0) {
            strncpy(buffer, def, bufferLen); 
            buffer[bufferLen - 1] = '\0';
            return strlen(buffer); 
        } 
    } while (strcmp(buff, t_section)); 

    do {   
        if (readLine(iniFile, buff) < 0 || buff[0] == '[') {
            strncpy(buffer, def, bufferLen);   
            buffer[bufferLen - 1] = '\0';  
            return strlen(buffer); 
        } 
    } while (strncmp(buff, entry, len)); 

    ep = strrchr(buff, '=');
    ep++; 

    strncpy(buffer, ep, bufferLen); 
    buffer[bufferLen - 1] = '\0'; 

    return strlen(buffer); 
} 

int iniFileGetSection(IniFile *iniFile,
                      char* section,
                      char* buffer, 
                      int   bufferLen)
{
    char buff[MAX_LINE_LENGTH]; 
    char t_section[MAX_LINE_LENGTH]; 
    int offset = 0;
    int len;

    rewindBuffer(iniFile);

    sprintf(t_section, "[%s]", section);

    do {   
        if (readLine(iniFile, buff) < 0) {
            buffer[offset++] = '\0';
            buffer[offset++] = '\0';
            return strlen(buffer); 
        } 
    } while (strcmp(buff, t_section)); 
    
    while ((len = readLine(iniFile, buff)) >= 0 && buff[0] != '[') {
        if (offset + len + 2 < bufferLen) {
            strcpy(buffer + offset, buff);
            offset += len + 1;
        }
    }

    buffer[offset++] = '\0';
    buffer[offset++] = '\0';

    return 1;
}

int iniFileWriteString(IniFile *iniFile,
                       char* section,
                       char* entry, 
                       char* buffer) 
{
    char buff[MAX_LINE_LENGTH]; 
    char t_section[MAX_LINE_LENGTH]; 
    char t_entry[MAX_LINE_LENGTH]; 
    int len;

    rewindBuffer(iniFile);

    createWriteBuffer(iniFile);

    sprintf(t_section, "[%s]", section);
    sprintf(t_entry, "%s=", entry);
    len = strlen(t_entry);

    do {  
        if (readLine(iniFile, buff) < 0) {  
            writeLine(iniFile, t_section);
            writeLine(iniFile, "\n");
            writeLine(iniFile, t_entry);
            writeLine(iniFile, buffer);
            writeLine(iniFile, "\n");
            destroyWriteBuffer(iniFile);
            return 1; 
        } 
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
    } while (strcmp(buff, t_section)); 

    for (;;) {   
        if (readLine(iniFile, buff) < 0) {
            writeLine(iniFile, t_entry);
            writeLine(iniFile, buffer);
            writeLine(iniFile, "\n");
            destroyWriteBuffer(iniFile);
            return 1; 
        } 

        if (!strncmp(buff, t_entry, len) || buff[0] == '[') {
            break; 
        }
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
    } 

    writeLine(iniFile, t_entry);
    writeLine(iniFile, buffer);
    writeLine(iniFile, "\n");

    if (strncmp(buff, t_entry, len)) {
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
    }
    while (readLine(iniFile, buff) >= 0) {
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
    }

    destroyWriteBuffer(iniFile);

    return 1; 
} 


int iniFileWriteSection(IniFile *iniFile,
                        char* section,
                        char* buffer)
{
    char buff[MAX_LINE_LENGTH]; 
    char t_section[MAX_LINE_LENGTH]; 
    int len; 

    rewindBuffer(iniFile);

    createWriteBuffer(iniFile);

    sprintf(t_section, "[%s]", section);

    while (readLine(iniFile, buff) >= 0 && strcmp(buff, t_section) != 0) {
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
    }
    
    writeLine(iniFile, t_section);
    writeLine(iniFile, "\n");
    while (*buffer != '\0') {
        writeLine(iniFile, buffer);
        writeLine(iniFile, "\n");
        buffer += strlen(buffer) + 1;
    }
    
    while ((len = readLine(iniFile, buff)) >= 0 && buff[0] != '\0' && buff[0] != '[');

    while (len >= 0) {
        writeLine(iniFile, buff);
        writeLine(iniFile, "\n");
        len = readLine(iniFile, buff);
    }

    destroyWriteBuffer(iniFile);

    return 1;
}
