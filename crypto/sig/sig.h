#ifndef DSASIG_H
#define DSASIG_H

/*
** Michael Neises
** 5 june 2019
** signature alg over RSA with SHA512 thumbprint
*/

#include "rsa/rsaInterface.h"
#include "sha512/hasher.h"
#include <string.h>

#define PRIVATE_KEY_FILE "./crypto/sig/rsa/working/myPrivateKey.txt"

struct file_list_class
{
    char* msgFile;
    char* sigFile;
    char* privKeyFile;
};

// writes the signature to the input "sig"
void signMsgWithKey( char* msg, unsigned long long* sig, struct private_key_class* priv );

// writes the signature to the input "sig"
void signMsg( char* msg, unsigned long long* sig );

// writes the signature to the file given by sigFile
void signFile( char* msgFile, char* sigFile, char* privKeyFile );

// reads the signature in sigFile into sig
void readSigFile( unsigned long long* sig, char* sigFile );

// tests the signature against the hash
// returns 1 if they agree, 0 otherwise
int sigVerify( unsigned long long* sig, uint8_t* hash, struct public_key_class* pub );

// duplicate a string, with memory allocation
// don't forget to free it
char* dupstr( char* src );

// parse a special input string for a file_list_class
// input "msgFileName;sigFileName;privKeyFileName"
void readFileList( uint8_t* fileString, struct file_list_class* files );

// parse a signature into a bytestring
void sigToByteString( unsigned long long* sig, uint8_t* byteSig );

// invert the above function
void byteStringToSig( uint8_t* byteSig, unsigned long long* sig );

#endif
