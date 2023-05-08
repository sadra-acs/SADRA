mtype:msgType = { prcRaReq, intRaReq, intRaRes, resRaRes};
mtype:msgStatus = { success, failure, dontcare };

short PROCESSID  = 55;
short REQLENGTH  = 8;

short RW_PERMISSION  = 3;
short NO_PERMISSION  = 0;

short HASH_INTCAP = 567;
short HASH_PROCAP = 789;


short TREELENGTH  = 4;

short PENODEID  = 17;

//=======================================

typedef ProcessCap {
short intCapPtr;
short rsrc;
byte permissions;
byte isIndicator;
short length;
short procId;
short recProcId;
short hash;
}; 

typedef IntermediateCap {
short resCapPtr;
byte permissions;
byte isIndicator;
short length;
short procId;
short hash;
};

typedef ResourceCap {
byte permissions;
short start;
short length;
short procId;
};

typedef ProcessRequestDetails {
	short length;
	short procId;
	ProcessCap pCap;
}

typedef IntCtrlRequestDetails {
	short length;
	short nodeId;
	short procId;
	IntermediateCap iCap;
}

//a wrapper of process capability, it is used as an element of a list
typedef ProcessCapNode{
	ProcessCap proCap;
};

//a wrapper of intermediate capability, it is used as a node of a capability tree
typedef IntCapNode{
	bool valid;
	short parent;
	short firstChild;
	short leftSibling;
	short rightSibling;
	IntermediateCap intCap;
};

typedef ResCapNode{
	bool valid;
	short parent;
	short child;
	short leftSibling;
	short rightSibling;
	ResourceCap resCap;
}

ResCapNode resTree[4];
IntCapNode intTree[4];
ProcessCapNode delegatorCapSet[4];

chan A = [1] of { mtype:msgType, mtype:msgStatus, ProcessRequestDetails} // channel from the process to the intermediate controller
chan B = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap} // channel from the intermediate controller to  the process
chan C = [1] of {mtype:msgType, mtype:msgStatus, IntCtrlRequestDetails} // channel from the intermediate controller to  the resouce controller
chan D = [1] of { mtype:msgType, mtype:msgStatus, IntermediateCap} // channel from the resource controller to the intermediate controller


trace {
S0:
	if
	 :: A!prcRaReq,_ -> goto S1;
	fi;
S1:
	if
	 :: A?prcRaReq,_ -> goto S2;
	fi;
S2:
	if
	 :: C!intRaReq,_ -> goto S3;
	fi;
S3:
	if
	 :: C?intRaReq,_ -> goto S4;
	fi;
S4:
	if
	 :: D!resRaRes,success,_ -> goto S5;
	fi;
S5:
	if
	 :: D?resRaRes,success,_ -> goto S6;
	fi;
S6:
	if
	 :: B!intRaRes,success,_ -> goto S7;
	fi;
S7:
	if
	 :: B?intRaRes,success,_ ;
	fi;
}

//=======================================
/* Process's Functions */


inline noOfProcCaps(firstIndex, lastIndex, cnt)
{
	cnt = lastIndex - firstIndex + 1;	
}

inline insertProcessCaps(cap, lastIndex)
{
	lastIndex++; 

	delegatorCapSet[lastIndex].proCap.intCapPtr = cap.intCapPtr;
	delegatorCapSet[lastIndex].proCap.permissions = cap.permissions;
	delegatorCapSet[lastIndex].proCap.length = cap.length;
	delegatorCapSet[lastIndex].proCap.procId = cap.procId;
	delegatorCapSet[lastIndex].proCap.hash = cap.hash;
}

//=======================================
/* Intermediate-controller's Functions */

inline initICTree()
{
	intTree[0].valid = true;
	intTree[0].leftSibling = 0;
	intTree[0].intCap.permissions = NO_PERMISSION;
}

inline validIntCaps( cnt)
{
	cnt = 0;
	int i;
	for (i : 0 .. TREELENGTH - 1) {
		if 
		:: intTree[i].valid == true -> cnt++;
		:: else -> skip;
		fi;
	}
}

inline genIntRaReq(pRequest,iRequest)
{
	iRequest.nodeId = PENODEID;
	iRequest.procId = pRequest.procId;
}

inline insertIntCap(cap, ptr)
{
	ptr = 1;

	intTree[ptr].valid = true;
	intTree[ptr].intCap.resCapPtr = cap.resCapPtr;
	intTree[ptr].intCap.permissions = cap.permissions;
	intTree[ptr].intCap.procId = cap.procId;
	intTree[ptr].intCap.hash = cap.hash;
}

inline genProccessCap(ptr, cap)
{
	cap.intCapPtr = ptr;
	cap.permissions = intTree[ptr].intCap.permissions;
	cap.procId = intTree[ptr].intCap.procId;
	cap.length = intTree[ptr].intCap.length;
	cap.hash = HASH_PROCAP;
}

//=======================================
/* Resource-controller's Functions */

inline initRCTree()
{
	resTree[0].valid = true;
	resTree[0].leftSibling = 0;
	resTree[0].resCap.permissions = RW_PERMISSION;
}

inline validResCaps( cnt)
{
	cnt = 0;
	int i;
	for (i : 0 .. TREELENGTH - 1) {
		if 
		:: resTree[i].valid == true -> cnt++;
		:: else -> skip;
		fi;
	}
}

inline createResCaps(req, ptr)
{
	ptr = 1;

	resTree[ptr].valid = true;
	resTree[ptr].resCap.permissions = RW_PERMISSION;
	resTree[ptr].resCap.start = 0;
	resTree[ptr].resCap.procId = req.procId;
}

inline genIntermediateCaps( ptr, cap)
{
	cap.resCapPtr = ptr;
	cap.permissions = resTree[ptr].resCap.permissions;
	cap.procId = resTree[ptr].resCap.procId;
	cap.length = resTree[ptr].resCap.length;
	cap.hash = HASH_INTCAP;
}

//=======================================
//=======================================
//=======================================

active proctype Resource_Controller()
{
	printf("Entering the Resource Controller...\n");
	initRCTree();
	printf("Finishing initializing the Resource Controller ...\n");

	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short rCapPtr;
	mtype:msgStatus msgStts;
	IntCtrlRequestDetails iReqDtails;
	ResourceCap resCap;
	IntermediateCap iCap;

	validResCaps(initialValidCaps);
	assert(initialValidCaps == 1);

	C?intRaReq(msgStts, iReqDtails);
	assert(iReqDtails.procId == PROCESSID);

	createResCaps(iReqDtails, rCapPtr);
	validResCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1);

	genIntermediateCaps(rCapPtr, iCap);
	assert(iCap.procId == PROCESSID);
	assert(iCap.resCapPtr == rCapPtr);

	D!resRaRes(success, iCap);

	printf("The resource controller terminated, ALL GOOD\n");
}

active proctype Intermediate_Controller()
{
	printf("Entering the Intermediate Controller...\n");
	initICTree();
	printf("Finishing initializing the Intermediate Controller ...\n");

	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short iCapPtr;
	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDtails;
	IntCtrlRequestDetails iReqDtails;
	IntermediateCap intCap;
	ProcessCap pCap;

	validIntCaps(initialValidCaps);
	assert(initialValidCaps == 1);

	A?prcRaReq(msgStts, pReqDtails);
	assert(pReqDtails.procId == PROCESSID);

	msgStts = dontcare;
	genIntRaReq(pReqDtails,iReqDtails);
	C!intRaReq(msgStts, iReqDtails);

	D?resRaRes(msgStts, intCap);
	assert(msgStts == success);
	assert(intCap.procId == PROCESSID);

	insertIntCap(intCap, iCapPtr);

	validIntCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1);

	genProccessCap(iCapPtr, pCap);
	assert(pCap.procId == PROCESSID)

	B!intRaRes(success, pCap);

	printf("The intermediate controller terminated, ALL GOOD\n");
}

active proctype Process()
{
	printf("entering process...\n");

	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDtails;
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps;
	int finalValidCaps;

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);
	assert(initialValidCaps == 0 );

	pReqDtails.procId = PROCESSID;
	msgStts = dontcare;
	A!prcRaReq(msgStts, pReqDtails);

	B?intRaRes(msgStts, pCap);
	assert(pCap.procId == PROCESSID);
	assert(pCap.permissions == RW_PERMISSION);

	insertProcessCaps(pCap, lastCapIndex);
	noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1 );

	printf("The process terminated, ALL GOOD\n");
}
