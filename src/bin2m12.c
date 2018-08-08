/*
 *	BIN to MZ Sharp M/C file
 *
 *	Stefano Bodrato 4/5/2000
 *  Vincent Cruz    10/3/2018
 *
 *	$Id: bin2m12.c,v 1.2 2001-04-12 13:26:13 stefano Exp $
 */

#include <stdio.h>
/* stdlib.h MUST be included to really open files as binary */
#include <stdlib.h>
#include <string.h>

#define MZ_MAIN_ENTRY 0x1200
#define MZ_TAPE_NAME_LEN 17

static void writeword(unsigned int i, FILE *fp) {
	fputc(i & 0xff, fp);
	fputc((i >> 8) & 0xff, fp);
}

int main(int argc, char *argv[]) {
	char	name[17];
	FILE	*fpin, *fpout;
	int	c;
	int	i;
	int	len;

	if (argc != 4 ) {
		fprintf(stderr, "Usage: %s [binary file] [Sharp MZ .m12 file] [program name]\n",argv[0]);
		return EXIT_FAILURE;
	}

    len = strlen(argv[3]);
    if (len > (MZ_TAPE_NAME_LEN-1)) {
        len = MZ_TAPE_NAME_LEN - 1;
    }
    fprintf(stdout, "program name: ");
    for(i=0; i<len; i++) {
        c = argv[3][i];
        if((c >= 'a') && (c <= 'z')) {
            c = 'A' + c - 'a';
        }
        else if((c < 0x20) || (c >= 0x60)) {
            c = 0x68;
        }
        name[i] = c;
        fputc(c, stdout);
    }
    fputc('\n', stdout);
    for(; i<MZ_TAPE_NAME_LEN; i++) {
        name[i] = 0xd;
    }

	if ( (fpin=fopen(argv[1], "rb") ) == NULL ) {
		fprintf(stderr, "Can't open input file\n");
		return EXIT_FAILURE;
	}

    /*
     *	Now we try to determine the size of the file
     *	to be converted
     */
	if (fseek(fpin, 0L, SEEK_END)) {
		fprintf(stderr, "Couldn't determine size of file\n");
		fclose(fpin);
		return EXIT_FAILURE;
	}

	len = ftell(fpin);
	fseek(fpin, 0L, SEEK_SET);

    fprintf(stdout, "size: %d bytes\n", len);
    fprintf(stdout, "m12 size: %d bytes\n", 18 + 6 + 104 + len);

	if ( (fpout=fopen(argv[2], "wb") ) == NULL ) {
		fprintf(stderr, "Can't open output file: %s\n", argv[2]);
		return EXIT_FAILURE;
	}

    /* Write out the MZ file */
	fputc(1,fpout); /* MZ80K M/C file */
	if ( (fwrite(name, 1, MZ_TAPE_NAME_LEN, fpout) != MZ_TAPE_NAME_LEN) ) {
	    fprintf(stderr, "Failed to write tape name to %s\n", argv[2]);
        fclose(fpout);
	    return EXIT_FAILURE;
	}
    	
	writeword(len, fpout);
	writeword(MZ_MAIN_ENTRY, fpout);
	writeword(MZ_MAIN_ENTRY, fpout);

	for	(i=0; i<104; i++) {
		fputc(0,fpout);
	}
	
	/* ... M/C ...*/
	for (i=0; i<len;i++) {
		c=getc(fpin);
		fputc(c,fpout);
	}

	fclose(fpin);
	fclose(fpout);

    return EXIT_SUCCESS;
}
