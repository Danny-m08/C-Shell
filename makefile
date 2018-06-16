#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <readline/readline.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <signal.h>
#include <ctype.h>
#include <unistd.h>


static const char prompt[] = "cssh> ";
static const char sep[] = " \t\n\r"; /* word separators*/

int newfile(char ** arg, int *count){
	int i = 0;
	for(; i < *count; i++){
		if( strcmp( arg[i], ">" ) == 0){
			int it = i;
			i = open( arg[++i], O_CREAT | O_WRONLY, S_IWUSR | S_IRUSR);	
			arg[it] = NULL;							
			arg[it + 1] = NULL;						
									
			for(; (it + 2) < *count; ++it){					
				arg[it] = arg[it + 2];					
				}
			*count  = *count - 2;						
			return i;							
			}	
		}	
	return -1;
	}

int Redirect( char ** arg, int *count){
	int i = 0;
        for(; i < *count; i++){
                if( strcmp( arg[i], "<" ) == 0){			
                        int it = i;					
			i = open( arg[++i], O_RDONLY);
			arg[it] = NULL;
                        arg[it + 1] = NULL;							
                        for(; (it + 2) < *count; ++it){			
                                arg[it] = arg[it + 2];			
                                }
                        *count  = *count - 2;				
                        return i;					
                }
       
        }
	return -1;
}


void clear( char ** arg){				
	int i = 0;
	while( i < 10){					
	 arg[i] = NULL;
	 ++i;
	 }
	}

	
int tokenize( char ** arg, char *line){
	int i = 0;
	int it = 0;
	while( line[i] != '\0' ){
		if ( !isspace( line[i] ) && line[i] != '\''){
			arg[it] = &line[i];	 
			++it;
			++i;
			while( i < 50 ){
				if( isspace( line[i])){
					line[i] = '\0';
					break;
					}
				else if( line[i] == '\0' )
					return it;
				++i;
				}
			}
		else if( line[i] == '\''){
			++i;
			arg[it] = &line[i];
			++it;
			while( 1 ){
				if( line[i] == '\'' ){
					line[i] = '\0';
					break;
					}
				++i;
				}
			}
		++i;
		}
	return it;
	}

int isPipe( char * line){
	int i = 0;
	while( line[i] != '\0' ){
		if (line[i] == '|') return ++i;
		++i;
		}
	return -1;
	}

int fix( char ** arg, char ** arg2){
	int i = 0;
	int it = 0;
	while( i < 10 && arg[i] != NULL){
		if( strcmp( arg[i], "|" ) == 0 ){
			arg[i] = NULL;
			++i;
			while( arg[i] != NULL ){
				arg2[it] = arg[i];
				arg[i] = NULL;
				++i;
				++it;
				}
			return it;
			}
		++i;}
	return -1;
	}

int main(){
 int pipes[2];
 int ac, ac2; 			
 int pid, cid, w; 
 int newFile = -1;		
 int redirect = -1; 		
 int status;		
 int _pipe;
 /*void (*istat)(int), (*qstat)(int);*/
 char *av[10] = {NULL}; 	
 char *av2[10] = {NULL};
 char *line;
 /*int wo;
 int st;*/
 while (1){
	

 	line = readline(prompt);
 	if (line == NULL)
 	 break;
	
	if (strlen(line) == 0){
	 free(line);
	 continue;
	 }

 	_pipe = isPipe(line);

	/*Check for pipe
 	Tokenize considering pipe 	*/
 	if (_pipe != -1){
                ac = tokenize( av, line);
                ac2 = fix (av, av2);
		ac = ac - (ac2 + 1);            
		redirect = Redirect( av, &ac);
		newFile = newfile( av2, &ac2);
                }
        else {
		ac = tokenize (av, line);
 		redirect = Redirect( av, &ac);
        	newFile = newfile( av, &ac);
		}
	if( ac == 0 ){
		}

/*	cd implementation */

 	if( strcmp( av[0], "cd" ) == 0 ){	
			
		if( av[1] == NULL || strcmp( av[1], "~") == 0 || strcmp( av[1], "~/") == 0 || strcmp(av[1], "") == 0) 
			chdir( getenv("HOME"));				
		 	
			
		else if( chdir( av[1] ) == -1)
			fprintf(stderr, "%s: No such file or directory.\n", av[1]);
			}
/*	exit implementation */
		
	else if ( strcmp(av[0], "exit") == 0){
		if( ac == 1){
			free(line);
			break;
			}
		else if( ac > 1)
			fprintf(stderr, "exit: Expression Syntax.\n");
 	 	}

/*	implementation of fork
 *	and pipe, if needed */

	else  {
		if( _pipe != -1 )
			pipe(pipes);

		if( (pid = fork()) == 0){
			if( _pipe != -1){
				dup2(pipes[1],1);
				close(pipes[0]);	
			 	}
			else if( newFile != -1 )
				dup2( newFile, 1);
			
			if( redirect != -1)
				dup2( redirect,0);

			execvp( av[0], av);
			fprintf(stderr, "%s: command not found\n", av[0]);
 			exit(EXIT_FAILURE);
			close(newFile);
			close(redirect);	
			}
		
		while ((w = wait(&status)) != pid && w != -1)
		 continue;
		close(redirect);

		if( _pipe != -1 ){
			if( (cid = fork()) == 0){		
				if( newFile != -1)
					dup2( newFile, 1);
				dup2(pipes[0], 0);			
				close(pipes[1]);
				execvp(av2[0],av2);
				fprintf(stderr, "%s: command not found\n", av2[0]);
                	     	exit(EXIT_FAILURE);
				}
			close(pipes[1]);
			close(pipes[0]);
			close(newFile);
			w = 0;
			while ((w = wait(&status)) != cid && w != -1)
 	                continue;
			}
		
		close(newFile);
		}	
		
	free(line);
 	clear(av);
	clear(av2);
	}
 exit(EXIT_SUCCESS);
}
