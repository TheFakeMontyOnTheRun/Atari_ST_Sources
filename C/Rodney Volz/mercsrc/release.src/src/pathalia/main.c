/* pathalias -- by steve bellovin, as told to peter honeyman */
#ifndef lint
static char	*sccsid = "@(#)main.c	9.5 88/06/10";
#endif

#define MAIN	/* for sccsid in header files */

#include "def.h"

/* exports */
char *Cfile;	/* current input file */
char *Graphout;	/* file for dumping edges (-g option) */
char *Linkout;	/* file for dumping shortest path tree */
char **Argv;	/* external copy of argv (for input files) */
node *Home;	/* node for local host */
int Cflag = 0;	/* print costs (-c option) */
int Dflag = 0;	/* penalize routes beyond domains (-D option) */
int Iflag = 0;	/* ignore case (-i option) */
int Tflag = 0;	/* trace links (-t option) */
int Vflag = 0;	/* verbose (-v option) */
int Fflag = 0;	/* print cost of first hop */
int Lineno = 1;	/* line number within current input file */
int Argc;	/* external copy of argc (for input files) */
extern void die();
extern int tracelink();

/* imports */
extern char *optarg;
extern int optind;
extern long Lcount, Ncount;
extern long allocation();
extern void wasted(), mapit(), hashanalyze(), deadlink();
extern char *local();
extern node *addnode();
extern int getopt(), yyparse();
extern void printit();

#define USAGE "usage: %s [-vciDf] [-l localname] [-d deadlink] [-t tracelink] [-g edgeout] [-s treeout] [-a avoid] [files ...]\n"

main(argc, argv) 
	register int argc; 
	register char **argv;
{	char *locname = 0, *bang;
	register int c;
	int errflg = 0;

	setbuf(stderr, (char *) 0);
	(void) allocation();	/* initialize data space monitoring */
	Cfile = "[deadlinks]";	/* for tracing dead links */
	Argv = argv;
	Argc = argc;

	while ((c = getopt(argc, argv, "cd:Dfg:il:s:t:v")) != EOF)
		switch(c) {
		case 'c':	/* print cost info */
			Cflag++;
			break;
		case 'd':	/* dead host or link */
			if ((bang = index(optarg, '!')) != 0) {
				*bang++ = 0;
				deadlink(addnode(optarg), addnode(bang));
			} else
				deadlink(addnode(optarg), (node *) 0);
			break;
		case 'D':	/* penalize routes beyond domains */
			Dflag++;
			break;
		case 'f':	/* print cost of first hop */
			Cflag++;
			Fflag++;
			break;
		case 'g':	/* graph output file */
			Graphout = optarg;
			break;
		case 'i':	/* ignore case */
			Iflag++;
			break;
		case 'l':	/* local name */
			locname = optarg;
			break;
		case 's':	/* show shortest path tree */
			Linkout = optarg;
			break;
		case 't':	/* trace this link */
			if (tracelink(optarg) < 0) {
				fprintf(stderr, "%s: can trace only %d links\n", Argv[0], NTRACE);
				exit(1);
			}
			Tflag = 1;
			break;
		case 'v':	/* verbose stderr, mixed blessing */
			Vflag++;
			break;
		default:
			errflg++;
		}

	if (errflg) {
		fprintf(stderr, USAGE, Argv[0]);
		exit(1);
	}
	argv += optind;		/* kludge for yywrap() */

#ifndef MWC
	if (*argv)
		freopen("/dev/null", "r", stdin);
	else
#endif
		Cfile = "[stdin]";

	if (!locname)
#ifdef MWC
	{
		fprintf(stderr,"Please set your local node name with\n");
		fprintf(stderr,"option \"-l <nodename>\". Thanks.\n");

		exit(2);
	}
#else
		locname = local();
#endif MWC
	if (*locname == 0) {
		locname = "lostinspace";
		fprintf(stderr, "%s: using \"%s\" for local name\n",
				Argv[0], locname);
	}

	Home = addnode(locname);	/* add home node */
	Home->n_cost = 0;		/* doesn't cost to get here */

	(void) yyparse();			/* read in link info */

	if (Vflag > 1)
		hashanalyze();
	vprintf(stderr, "%d nodes, %d links, alloc %ldk\n", 
				Ncount, Lcount, allocation());

	Cfile = "[backlinks]";	/* for tracing back links */
	Lineno = 0;

	/* compute shortest path tree */
	mapit();
	vprintf(stderr, "allocation is %ldk after mapping\n", allocation());

	/* traverse tree and print paths */
	printit();
	vprintf(stderr, "allocation is %ldk after printing\n", allocation());

	wasted();	/* how much was wasted in memory allocation? */

	return 0;
}

void
die(s)
	char *s;
{
#ifdef DEBUG
	extern int abort();

	fprintf(stderr, "%s: %s\n", Argv[0], s);
	fflush(stdout);
	fflush(stderr);
	abort();
#else
	fprintf(stderr, "%s: %s; notify the authorities\n", Argv[0], s);
	exit(-1);
#endif
}
