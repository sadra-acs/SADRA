mtype:msgType = { prcERReq, intERReq, intERConfRes,resERConfRes};
mtype:msgStatus = { success, failure, dontcare };

short DELEGATOR_PROCESS_ID   = 55;
short CAP_RECEIVER_PROCESS_ID  = 77;

short REQLENGTH  = 8;

short CAP_DELEGATOR_NODE_ID  = 433;
short CAP_RECEIVER_NODE_ID   = 655;

short CAPESETLENGTH  = 4;
short RESOURCE = 9;

short RW_PERMISSION  = 3;
short R_PERMISSION  = 1;
short NO_PERMISSION  = 0;

short INTCAPPTR = 1;
short RESCAPPTR = 1;
short INDICAPPTR = 2;
short INDRCAPPTR = 2;

short HASH_PROCAP    = 123;
short HASH_RECPROCAP = 234;
short HASH_INTCAP    = 345;
short HASH_RECINTCAP = 456;
short HASH_INDICATOR_PROCAP = 567;
short HASH_INDICAP   = 678;
short HASH_INDPCAP = 789;

short TREELENGTH  = 4;

//=======================================

typedef ProcessCap {
	short intCapPtr;
	short rsrc;
	byte  permissions;
	byte  isIndicator;
	short length;
	short procId;
	short capRecProcId;
	short hash;
}; 

typedef IntermediateCap {
	short resCapPtr;
    short rsrc;
    byte  permissions;
    byte  isIndicator;
    short length;
    short procId;
    short capRecProcId;
    short capRecNodeId;
    short hash;
};

typedef ResourceCap {
    byte  permissions;
    short rsrc;
    short procId;
    short nodeId;
};

typedef ProcessRequestDetails {
	short length;
	short procId;
	short nodeId;
	short capReceiverProcId;
	short capReceiverNodeId;
	short delegated_permissions;
	ProcessCap pCap;
}

typedef IntCtrlRequestDetails {
	short length;
	short senderNodeId;
	short procId;
	short capReceiverProcId;
	short capReceiverNodeId;
	short delegated_permissions;
	short intCapPtr;
	IntermediateCap iCap;
}

typedef IntCtrlResponseDetails {
	short procId;
	short delegatedICapPtr;
	IntermediateCap iCap;
}


typedef ResCtrlResponseDetails {
	short nodeId;
	short procId;
	short delegatedICapPtr;
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
	short hashProCap;
};

typedef ResCapNode{
	bool valid;
	short parent;
	short child;
	short leftSibling;
	short rightSibling;
	ResourceCap resCap;
	short hashIntCap
}


ResCapNode resTree[4];
IntCapNode delIntTree[4];
ProcessCapNode delegatorCapSet[4];

chan A = [1] of { mtype:msgType, mtype:msgStatus, ProcessRequestDetails} // channel from the delegator process to the intermediate controller
chan B = [1] of {mtype:msgType, mtype:msgStatus, IntCtrlResponseDetails} // channel from the intermediate controller to  the delegator process
chan C = [1] of {mtype:msgType, mtype:msgStatus, IntCtrlRequestDetails} // channel from the intermediate controller to  the resouce controller
chan D = [1] of {mtype:msgType, mtype:msgStatus, ResCtrlResponseDetails} // channel from the resource controller to the intermediate controller

trace {
S0:
   if
    :: A!prcERReq,_ -> goto S1;
   fi;
S1:
   if
    :: A?prcERReq,_ -> goto S2;
   fi;
S2:
   if
    :: C!intERReq,_ -> goto S3;
   fi;
S3:
   if
    :: C?intERReq,_ -> goto S4;
   fi;
S4:
   if
    :: D!resERConfRes,success,_ -> goto S5;
   fi;
S5:
   if
    :: D?resERConfRes,success,_ -> goto S6;
   fi;
S6:
   if
    :: B!intERConfRes,success,_ -> goto S7;
   fi;
S7:
   if
    :: B?intERConfRes,success,_ ;
   fi;
}
//=======================================
/* Process's Functions */


inline noOfProcCaps(firstIndex, lastIndex, cnt)
{
	cnt = lastIndex - firstIndex + 1;	
}

inline initDelProcess(firstIndex, lastIndex)
{
	lastIndex++; 
	
	delegatorCapSet[lastIndex].proCap.intCapPtr   = INTCAPPTR;
	delegatorCapSet[lastIndex].proCap.rsrc        = RESOURCE;
	delegatorCapSet[lastIndex].proCap.permissions = RW_PERMISSION;
	delegatorCapSet[lastIndex].proCap.procId      = DELEGATOR_PROCESS_ID;
	delegatorCapSet[lastIndex].proCap.hash        = HASH_PROCAP;

    lastIndex++;

	delegatorCapSet[lastIndex].proCap.intCapPtr    = INDICAPPTR;
	delegatorCapSet[lastIndex].proCap.isIndicator  = true;
	delegatorCapSet[lastIndex].proCap.rsrc         = RESOURCE;
	delegatorCapSet[lastIndex].proCap.permissions  = R_PERMISSION;
	delegatorCapSet[lastIndex].proCap.procId       = DELEGATOR_PROCESS_ID;
	delegatorCapSet[lastIndex].proCap.capRecProcId = CAP_RECEIVER_PROCESS_ID;
	delegatorCapSet[lastIndex].proCap.hash         = HASH_INDPCAP;
}

inline getPCap(index, cap)
{
	cap.intCapPtr = delegatorCapSet[index].proCap.intCapPtr;
	cap.isIndicator = delegatorCapSet[index].proCap.isIndicator;
	cap.procId = delegatorCapSet[index].proCap.procId;
	cap.capRecProcId = delegatorCapSet[index].proCap.capRecProcId;
	cap.permissions = delegatorCapSet[index].proCap.permissions;
}

inline deleteCap(index)
{
	index = index - 1;
}
//=======================================
/* Intermediate-controller's Functions */

inline initDelelgatorICTree()
{
	delIntTree[0].valid                 = true;
	delIntTree[0].leftSibling           = 1;
	delIntTree[0].intCap.permissions    = NO_PERMISSION;
	delIntTree[1].valid                 = true;
	delIntTree[1].parent                = 0;
	delIntTree[1].hashProCap            = HASH_PROCAP;	
	delIntTree[1].intCap.resCapPtr      = RESCAPPTR;
    delIntTree[1].intCap.procId         = DELEGATOR_PROCESS_ID;
    delIntTree[1].intCap.capRecProcId   = 0;
    delIntTree[1].intCap.capRecNodeId   = 0;
    delIntTree[1].intCap.rsrc           = RESOURCE;
    delIntTree[1].intCap.permissions    = RW_PERMISSION;
    delIntTree[1].intCap.isIndicator    = false;
    delIntTree[1].intCap.hash           = HASH_INTCAP;
    delIntTree[2].valid                 = true;
    delIntTree[2].parent                = 1;
	delIntTree[2].hashProCap            = HASH_INDPCAP;	
	delIntTree[2].intCap.resCapPtr      = INDRCAPPTR;
    delIntTree[2].intCap.procId         = DELEGATOR_PROCESS_ID;
    delIntTree[2].intCap.capRecProcId   = CAP_RECEIVER_PROCESS_ID;
    delIntTree[2].intCap.capRecNodeId   = 2;
    delIntTree[2].intCap.rsrc           = RESOURCE;
    delIntTree[2].intCap.permissions    = R_PERMISSION;
    delIntTree[2].intCap.isIndicator    = true;
    delIntTree[2].intCap.hash           = HASH_INDICAP;
}

inline validDelIntCaps( cnt)
{
	cnt = 0;
	int i;
	for (i : 0 .. TREELENGTH - 1) {
		if 
		:: delIntTree[i].valid == true -> cnt++;
		:: else -> skip;
		fi;
	}
}

inline genIntERReq(pRequest,iRequest)
{
	short idx = pRequest.pCap.intCapPtr;

	iRequest.senderNodeId          = CAP_DELEGATOR_NODE_ID;
	iRequest.procId                = pRequest.procId;
	iRequest.capReceiverProcId     = pRequest.capReceiverProcId;
	iRequest.capReceiverNodeId     = pRequest.capReceiverNodeId;
	iRequest.delegated_permissions = pRequest.delegated_permissions;
	iRequest.intCapPtr             = idx;

    
	iRequest.iCap.resCapPtr    = delIntTree[idx].intCap.resCapPtr;
	iRequest.iCap.isIndicator  = delIntTree[idx].intCap.isIndicator;
	iRequest.iCap.rsrc         = delIntTree[idx].intCap.rsrc;
	iRequest.iCap.permissions  = delIntTree[idx].intCap.permissions;
	iRequest.iCap.procId       = delIntTree[idx].intCap.procId; 
	iRequest.iCap.capRecProcId = delIntTree[idx].intCap.capRecProcId;
	iRequest.iCap.hash         = delIntTree[idx].intCap.hash;

}

inline removeICSubtree( ptr)
{
	delIntTree[ptr].firstChild = 0;
}

inline removeICChild(parentPtr, childPtr)
{
	delIntTree[parentPtr].firstChild = 0;
}

inline revokeICap(ptr)
{
	delIntTree[ptr].valid = false;
	short parent = delIntTree[ptr].parent;
    delIntTree[ptr].parent = 0;
    removeRCSubtree(ptr);
    removeRCChild(parent, ptr);	
}

inline genIntCtrlERConfRes(pRequest,iResponse)
{
	iResponse.procId = pRequest.procId;
	iResponse.delegatedICapPtr = pRequest.pCap.intCapPtr;
}
//=======================================
/* Resource-controller's Functions */

inline initRCTree()
{
	resTree[0].valid              = true;
	resTree[0].leftSibling        = 1;
	resTree[0].resCap.permissions = RW_PERMISSION;
	resTree[1].valid              = true;
	resTree[1].parent             = 0;
	resTree[1].leftSibling        = 1;
	resTree[1].resCap.rsrc        = RESOURCE;
	resTree[1].resCap.permissions = RW_PERMISSION;
	resTree[1].resCap.procId      = DELEGATOR_PROCESS_ID;
	resTree[1].resCap.nodeId      = CAP_DELEGATOR_NODE_ID;
	resTree[2].valid              = true;
	resTree[1].parent             = 1;
	resTree[2].leftSibling        = 0;
	resTree[2].resCap.rsrc        = RESOURCE;
	resTree[2].resCap.permissions = R_PERMISSION;
	resTree[2].resCap.procId      = CAP_RECEIVER_PROCESS_ID;
	resTree[2].resCap.nodeId      = 2;
	resTree[2].hashIntCap         = HASH_INDICAP;
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

inline assertIntERReq(iReqDetails)
{
	short resCapIndex = iReqDetails.iCap.resCapPtr;
	assert(iReqDetails.iCap.isIndicator == true);
	assert(iReqDetails.iCap.rsrc == resTree[resCapIndex].resCap.rsrc);
	assert(iReqDetails.iCap.permissions == resTree[resCapIndex].resCap.permissions);
	assert(iReqDetails.iCap.capRecProcId == resTree[resCapIndex].resCap.procId);
	assert(iReqDetails.iCap.hash == resTree[resCapIndex].hashIntCap);
}

inline removeRCSubtree( ptr)
{
	resTree[ptr].child = 0;
}

inline removeRCChild(parentPtr, childPtr)
{
	resTree[parentPtr].child = 0;
}

inline revokeRCap(ptr)
{
	resTree[ptr].valid = false;
	short parent = resTree[ptr].parent;
    resTree[ptr].parent = 0;
    removeRCSubtree(ptr);
    removeRCChild(parent, ptr);	
}

inline genResCtrlERConfRes(iRequest,rResponse)
{
	rResponse.procId = iRequest.procId;
	rResponse.nodeId = iRequest.senderNodeId;
	rResponse.delegatedICapPtr = iRequest.intCapPtr;
}
//=======================================
//=======================================
//=======================================

active proctype Process()
{
	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDetails;
	IntCtrlResponseDetails iResDetails
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps;
	int finalValidCaps;

	initDelProcess(firstCapIndex, lastCapIndex);
	printf("Initializing the Delegator Process...\n");

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);
    assert(initialValidCaps == 2 );

    getPCap(lastCapIndex, pReqDetails.pCap);
    pReqDetails.procId = DELEGATOR_PROCESS_ID;
	
	msgStts = dontcare;
	A!prcERReq(msgStts, pReqDetails);

	B?intERConfRes(msgStts, iResDetails); 
	assert(msgStts == success);
	assert(iResDetails.procId == DELEGATOR_PROCESS_ID);
	assert(iResDetails.delegatedICapPtr == pReqDetails.pCap.intCapPtr);

	deleteCap(lastCapIndex);
	noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
    assert(finalValidCaps == initialValidCaps - 1 );*/
}

active proctype Intermediate_Controller()
{
	printf("entering the Intermediate Controller...\n");
	initDelelgatorICTree();
	printf("finishing initializing the Intermediate Controller ...\n");

	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short delICapPtr;
	mtype:msgStatus msgStts;
    ProcessRequestDetails pReqDetails;
    IntCtrlRequestDetails iReqDetails;
    IntCtrlResponseDetails iResDetails
    ResCtrlResponseDetails rResDetails;

	validDelIntCaps(initialValidCaps);
	assert(initialValidCaps == 3);

	A?prcERReq(msgStts, pReqDetails);
	assert(pReqDetails.procId == DELEGATOR_PROCESS_ID);
	assert(pReqDetails.pCap.isIndicator == true);
	assert(pReqDetails.pCap.procId == DELEGATOR_PROCESS_ID);
	assert(pReqDetails.pCap.capRecProcId == CAP_RECEIVER_PROCESS_ID);
	assert(pReqDetails.pCap.permissions == R_PERMISSION);

	msgStts = dontcare;
	genIntERReq(pReqDetails,iReqDetails);
	C!intERReq(msgStts, iReqDetails);

	D?resERConfRes(msgStts, rResDetails);
	assert(msgStts == success);
	assert(rResDetails.procId == DELEGATOR_PROCESS_ID);
	assert(rResDetails.delegatedICapPtr == pReqDetails.pCap.intCapPtr);

	revokeICap(rResDetails.delegatedICapPtr);

	validDelIntCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps - 1);

    genIntCtrlERConfRes(pReqDetails,iResDetails);
    B!intERConfRes(success, iResDetails); 
}

active proctype Resource_Controller()
{
	printf("Entering the Resource Controller...\n");
	initRCTree();
	printf("Finishing initializing the Resource Controller ...\n");

	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short rCapPtr;
	short delRCapPtr;
	mtype:msgStatus msgStts;
    IntCtrlRequestDetails iReqDetails;
    ResCtrlResponseDetails rResDetails;
    IntermediateCap iCap;
    IntermediateCap indicatorICap;

    validResCaps(initialValidCaps);
    assert(initialValidCaps == 3);

    C?intERReq(msgStts, iReqDetails);
	assertIntERReq(iReqDetails);

	revokeRCap(iReqDetails.iCap.resCapPtr);

	validResCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps - 1);

    genResCtrlERConfRes(iReqDetails,rResDetails);
    D!resERConfRes(success, rResDetails); 
}