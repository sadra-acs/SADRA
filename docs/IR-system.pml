
mtype:msgType = { prcIRReq, intIRRes};
mtype:msgStatus = { success, failure, dontcare };

/*short DELPROCESSID  = 55;
short RECEIVERPROCESSID  = 77;
short NODEID  = 344;
short RECEIVERNODEID  = 366;
short REQLENGTH  = 8;
short TREELENGTH  = 4;
short CAPESETLENGTH  = 4;
short RANDOMNO_INTCAP  = 3456;
short RANDOMNO_PROCAP  = 7654;
short WR_PERMISSION  = 3;
short R_PERMISSION  = 1;
short HASH_INTCAP = 234;
short HASH_INDICAP = 432;
short HASH_PROCAP = 567;
short HASH_INDPCAP = 765;
short INTCAPPTR = 1;
short INDICAPPTR = 2;*/

short DELPROCESSID  = 55;
short RECEIVERPROCESSID  = 77;

short REQLENGTH  = 8;

short NODEID  = 344;
short RECEIVERNODEID  = 366;

short CAPESETLENGTH  = 4;
short DLERSRC = 9;

short RW_PERMISSION  = 3;
short R_PERMISSION  = 1;

short INTCAPPTR = 1;
short INDICAPPTR = 2;

short HASH_DELPROCCAP = 234;
short HASH_INDPROCCAP = 456;
short HASH_RECPROCCAP = 678;
short HASH_INTCAP = 234;
short HASH_INDPCAP = 765;
short HASH_PROCAP = 567;

short TREELENGTH  = 4;

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


typedef ProcessRequestDetails {
	short length;
	short procId;
	short receiverProcId;
	short receiverNodeId;
	ProcessCap pCap;
	short delegated_permissions;
}

//a wrapper of process capability, it is used as an element of a list
typedef ProcessCapNode{
	ProcessCap proCap;
};

//a wrapper of intermediate capability, it is used as a node of a capability tree
typedef intCapNode{
	bool valid;
	short parent;
	short firstChild;
	short leftSibling;
	short rightSibling;
	IntermediateCap intCap;
};

intCapNode intTree[4];
ProcessCapNode DelegatorCapSet[4];

chan A = [1] of { mtype:msgType, mtype:msgStatus, ProcessRequestDetails} // channel from the process to the intermediate controller
chan B = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap}

trace {
S0:
	if
	 :: A!prcIRReq,_ -> goto S1;
	fi;
S1:
	if
	 :: A?prcIRReq,_ -> goto S2;
	fi;
 S2:
	if
	 :: B!intIRRes,success,_ -> goto S3;
	fi;
S3:
	if
	 :: B?intIRRes,success,_ ;
	fi;
}

//=======================================
/* Process's Functions */

inline initDelProcess(firstIndex, lastIndex)
{
	lastIndex++; 
	
	DelegatorCapSet[lastIndex].proCap.intCapPtr = INTCAPPTR;
	DelegatorCapSet[lastIndex].proCap.rsrc = DLERSRC;
	DelegatorCapSet[lastIndex].proCap.permissions = RW_PERMISSION;
	DelegatorCapSet[lastIndex].proCap.procId = DELPROCESSID;
	DelegatorCapSet[lastIndex].proCap.recProcId = DELPROCESSID;
	DelegatorCapSet[lastIndex].proCap.hash = HASH_DELPROCCAP;

	lastIndex++;

	DelegatorCapSet[lastIndex].proCap.intCapPtr = INDICAPPTR;
	DelegatorCapSet[lastIndex].proCap.permissions = R_PERMISSION;
	DelegatorCapSet[lastIndex].proCap.isIndicator = true;
	DelegatorCapSet[lastIndex].proCap.procId = DELPROCESSID;
	DelegatorCapSet[lastIndex].proCap.recProcId = RECEIVERPROCESSID;
	DelegatorCapSet[lastIndex].proCap.hash = HASH_INDPCAP;
}

inline noOfProcCaps(firstIndex, lastIndex, cnt)
{
	cnt = lastIndex - firstIndex + 1;	
}

inline getPCap(index, cap)
{
	cap.intCapPtr = DelegatorCapSet[index].proCap.intCapPtr;
	cap.isIndicator = DelegatorCapSet[index].proCap.isIndicator;
	cap.procId = DelegatorCapSet[index].proCap.procId;
	cap.recProcId = DelegatorCapSet[index].proCap.recProcId;
	cap.permissions = DelegatorCapSet[index].proCap.permissions;
}

inline deleteCap(index)
{
	index = index - 1;
}

//=======================================
/* Intermediate-controller's Functions */

inline initTree()
{
	intTree[0].valid = true;
	intTree[0].leftSibling = 1;
	intTree[1].valid = true;
	intTree[1].parent = 0;	
	intTree[1].intCap.procId = DELPROCESSID;
	intTree[1].intCap.permissions = RW_PERMISSION;
	intTree[1].intCap.isIndicator = false;
	intTree[2].valid = true;
	intTree[2].parent = 1;	
	intTree[2].intCap.procId = RECEIVERPROCESSID;
	intTree[2].intCap.permissions = R_PERMISSION;
	intTree[2].intCap.isIndicator = false;
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

inline assertIRReq(pReqDtails)
{
	short intCapIndex = pReqDtails.pCap.intCapPtr;
	short parent = intTree[intCapIndex].parent;
	assert(pReqDtails.procId == intTree[parent].intCap.procId);
	assert(pReqDtails.pCap.isIndicator == true);
	assert(pReqDtails.pCap.procId == intTree[parent].intCap.procId);
	assert(pReqDtails.pCap.recProcId == intTree[intCapIndex].intCap.procId);
	assert(pReqDtails.pCap.permissions == intTree[intCapIndex].intCap.permissions);
}

inline removeSubtree( ptr)
{
	intTree[ptr].firstChild = 0;
}

inline removeChild(parentPtr, childPtr)
{
	intTree[parentPtr].firstChild = 0;
}

inline revokeCap(ptr)
{
	intTree[ptr].valid = false;
	short parent = intTree[ptr].parent;
	intTree[ptr].parent = 0;
	removeSubtree(ptr);
	removeChild(parent, ptr);	
}

//=======================================
//=======================================
//=======================================


active proctype IntermediateController()
{
	printf("entering the Intermediate Controller...\n");
	initTree();
	printf("finishing initializing the Intermediate Controller ...\n");

	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short delICapPtr;
	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDtails;
	ProcessCap indPCap;
	ProcessCap pCap;

	validIntCaps(initialValidCaps);
	assert(initialValidCaps == 3);

	A?prcIRReq(msgStts, pReqDtails);
	assertIRReq(pReqDtails);

	revokeCap(pReqDtails.pCap.intCapPtr);
	validIntCaps(finalValidCaps);
	assert(finalValidCaps < initialValidCaps);

	B!intIRRes(success, pReqDtails.pCap);

	printf("The intermediate controller terminated, ALL GOOD\n");

}

active proctype delegator_process()
{
	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDtails;
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps = 0;
	int finalValidCaps = 0;
	
	initDelProcess(firstCapIndex, lastCapIndex);
	printf("initializing the Delegator Process...\n");

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);
	assert(initialValidCaps == 2 );

	getPCap(lastCapIndex, pReqDtails.pCap);
	pReqDtails.procId = DELPROCESSID;
	
	msgStts = dontcare;
	A!prcIRReq(msgStts, pReqDtails);

	deleteCap(lastCapIndex);
	noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
	assert(finalValidCaps == initialValidCaps - 1 );
	printf("The process terminated, ALL GOOD\n");
}