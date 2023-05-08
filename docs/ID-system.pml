mtype:msgType = { prcIDReq, intIDRes, intIDConfRes};
mtype:msgStatus = { success, failure, dontcare };

short DELPROCESSID  = 55;
short RECEIVERPROCESSID  = 77;
short REQLENGTH  = 8;
short CAPESETLENGTH  = 4;
short TREELENGTH  = 4;
short DLERSRC = 9;
short RW_PERMISSION  = 3;
short R_PERMISSION  = 1;
short DEL_PERMISSION  = 1;
short HASH_DELPROCCAP = 234;
short HASH_INDPROCCAP = 456;
short HASH_RECPROCCAP = 678;
short INTCAPPTR = 1;
short HASH_INTCAP = 234;
short HASH_PROCAP = 567;

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
ProcessCapNode ReceiverCapSet[4];

chan A = [1] of { mtype:msgType, mtype:msgStatus, ProcessRequestDetails} // channel from the process to the intermediate controller
chan B = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap} // channel from the intermediate controller to  the process
chan C = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap} // channel from the intermediate controller to  the receiving process


trace {
S0:
   if
    :: A!prcIDReq,_ -> goto S1;
   fi;
S1:
   if
    :: A?prcIDReq,_ -> goto S2;
   fi;
S2:
   if
    :: B!intIDConfRes,success,_ -> goto S3;
   fi;
S3:
   if
    :: C!intIDRes,success,_ -> goto S4;
    :: B?intIDConfRes,success,_ -> goto S5;
   fi;
S4:
   if
    :: B?intIDConfRes,success,_ -> goto S6;
    :: C?intIDRes,success,_ -> goto S7;
   fi;
S5:
   if
    :: C!intIDRes,success,_ -> goto S6;
   fi;
S6:
   if
    :: C?intIDRes,success,_ ;
   fi;
S7:
   if
    :: B?intIDConfRes,success,_ ;
   fi;
}

//=======================================
/* Process's Functions */

inline insertDelProcessCaps(cap, lastIndex)
{
	lastIndex++; 

	DelegatorCapSet[lastIndex].proCap.intCapPtr = cap.intCapPtr;
	DelegatorCapSet[lastIndex].proCap.permissions = cap.permissions;
	DelegatorCapSet[lastIndex].proCap.length = cap.length;
	DelegatorCapSet[lastIndex].proCap.procId = cap.procId;
	DelegatorCapSet[lastIndex].proCap.hash = cap.hash;
}

inline insertRecProcessCaps(cap, lastIndex)
{
	lastIndex++; 

	ReceiverCapSet[lastIndex].proCap.intCapPtr = cap.intCapPtr;
	ReceiverCapSet[lastIndex].proCap.permissions = cap.permissions;
	ReceiverCapSet[lastIndex].proCap.length = cap.length;
	ReceiverCapSet[lastIndex].proCap.procId = cap.procId;
	ReceiverCapSet[lastIndex].proCap.hash = cap.hash;
}

inline noOfProcCaps(firstIndex, lastIndex, cnt)
{
	cnt = lastIndex - firstIndex + 1;	
}

inline initDelProcess(firstIndex, lastIndex)
{
	lastIndex++; 
	
	DelegatorCapSet[lastIndex].proCap.intCapPtr = INTCAPPTR;
	DelegatorCapSet[lastIndex].proCap.rsrc = DLERSRC;
	DelegatorCapSet[lastIndex].proCap.permissions = RW_PERMISSION;
	DelegatorCapSet[lastIndex].proCap.procId = DELPROCESSID;
	DelegatorCapSet[lastIndex].proCap.hash = HASH_DELPROCCAP;
}


inline generateRequest(reqDtails)
{
    reqDtails.procId = DELPROCESSID;
	reqDtails.receiverProcId = RECEIVERPROCESSID;
	reqDtails.pCap.intCapPtr = INTCAPPTR;
	reqDtails.pCap.permissions = RW_PERMISSION;
	reqDtails.delegated_permissions = R_PERMISSION;
}

//=======================================
/* Intermediate-controller's Functions */

inline initTree()
{
	intTree[0].valid = true;
	intTree[0].leftSibling = 1;
    intTree[1].valid = true;
    intTree[1].parent = 0;	
    intTree[1].intCap.permissions = RW_PERMISSION;
    intTree[1].intCap.procId = DELPROCESSID;
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

inline addChildNode(parent, child)
{
	intTree[parent].firstChild = child;
}

inline insertIntCaps(cap, ptr)
{
	ptr = 1;

	intTree[ptr].valid = true;
	intTree[ptr].intCap.resCapPtr = cap.resCapPtr;
	intTree[ptr].intCap.permissions = cap.permissions;
	intTree[ptr].intCap.length = cap.length;
	intTree[ptr].intCap.procId = cap.procId;
	intTree[ptr].intCap.hash = cap.hash;
}


inline genProccessCap( ptr, cap)
{
	cap.intCapPtr = ptr;
	cap.permissions = intTree[ptr].intCap.permissions;
	cap.procId = intTree[ptr].intCap.procId;
	cap.length = intTree[ptr].intCap.length;
	cap.hash = HASH_PROCAP;
}

inline genIndCap( ptr, cap)
{
	short parent = intTree[ptr].parent;

	cap.intCapPtr = ptr;
	cap.isIndicator = true;
	cap.permissions = intTree[ptr].intCap.permissions;
	cap.procId = intTree[parent].intCap.procId; 
	cap.recProcId = intTree[ptr].intCap.procId;
	cap.length = intTree[ptr].intCap.length;
	cap.hash = HASH_INTCAP;
}


inline delegateCap(reqDtails, ptr)
{
	ptr = 2;
	short intCapPtr = reqDtails.pCap.intCapPtr;

    intTree[ptr].valid = true;
    intTree[ptr].parent = intCapPtr;
    addChildNode(intCapPtr, ptr)

	intTree[ptr].intCap.resCapPtr = intTree[intCapPtr].intCap.resCapPtr;
	intTree[ptr].intCap.permissions = reqDtails.delegated_permissions;
	intTree[ptr].intCap.procId = reqDtails.receiverProcId;
	
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
    ProcessRequestDetails reqDtails;
    ProcessCap indPCap;
    ProcessCap pCap;

	validIntCaps(initialValidCaps);
	assert(initialValidCaps == 2);
	
	A?prcIDReq(msgStts, reqDtails);
	assert(reqDtails.procId == DELPROCESSID);
	assert(reqDtails.receiverProcId == RECEIVERPROCESSID);

	delegateCap(reqDtails, delICapPtr);

	validIntCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1);

    genIndCap(delICapPtr, indPCap);
   
    genProccessCap(delICapPtr, pCap);
   
    B!intIDConfRes(success, indPCap);

    C!intIDRes(success, pCap);

	printf("The intermediate controller terminated, ALL GOOD\n");
}

active proctype delegator_process()
{

	printf("entering delegator process...\n");

	mtype:msgStatus msgStts;
	ProcessRequestDetails reqDtails;
	ProcessCap pCap;
	ProcessCap indPCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps = 0;
	int finalValidCaps = 0;
	
	initDelProcess(firstCapIndex, lastCapIndex);
	printf("initializing the Delegator Process...\n");

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);

    assert(initialValidCaps == 1 );

    generateRequest(reqDtails);
	A!prcIDReq(msgStts, reqDtails);

	B?intIDConfRes(msgStts, indPCap);
    assert(indPCap.isIndicator == true)
	assert(indPCap.procId == DELPROCESSID)
    assert(indPCap.recProcId == RECEIVERPROCESSID)
    assert(indPCap.permissions == R_PERMISSION)

    insertDelProcessCaps(pCap, lastCapIndex);
    noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
    assert(finalValidCaps == initialValidCaps + 1 );

    printf("The delegator process terminated, ALL GOOD\n");
}

active proctype receiver_process()
{

	printf("entering receiver process...\n");

	mtype:msgStatus msgStts;
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps = 0;
	int finalValidCaps = 0;
	
	printf("initializing the Receiver Process...\n");

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);

    assert(initialValidCaps == 0 );

    C?intIDRes(msgStts, pCap);
    assert(pCap.isIndicator == false)
    assert(pCap.procId == RECEIVERPROCESSID)
    assert(pCap.permissions == R_PERMISSION)

    insertRecProcessCaps(pCap, lastCapIndex);
    noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
    assert(finalValidCaps == initialValidCaps + 1 );

    printf("The receiver process terminated, ALL GOOD\n");
}