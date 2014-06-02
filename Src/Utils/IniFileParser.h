/**************************************************************************­**** 
 PORTABLE ROUTINES FOR WRITING PRIVATE PROFILE STRINGS --  by Joseph J. Graf 
 Header file containing prototypes and compile-time configuration. 
***************************************************************************­***/ 

#ifndef INIFILE_PARSER_H
#define INIFILE_PARSER_H

#define MAX_LINE_LENGTH    512 

typedef struct IniFile IniFile;

IniFile *iniFileOpen(const char *filename);
IniFile *iniFileOpenZipped(const char *zipFile, const char *iniFilename);

const char *iniFileGetFilePath(IniFile *iniFile);

int iniFileClose(IniFile *iniFile);

int iniFileGetInt(IniFile *iniFile,
                  char* section,
                  char* entry,
                  int   def);
int iniFileGetString(IniFile *iniFile,
                     char* section,
                     char* entry,
                     char* defVal,
                     char* buffer,
                     int   bufferLen);
int iniFileGetSection(IniFile *iniFile,
                      char* section,
                      char* buffer,
                      int   bufferLen);
int iniFileWriteString(IniFile *iniFile,
                       char* section,
                       char* entry,
                       char* buffer);
int iniFileWriteSection(IniFile *iniFile,
                        char* section,
                        char* buffer);


#endif
