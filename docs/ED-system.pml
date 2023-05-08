mtype:msgType = { prcEDReq, intEDReq, intEDRes, intEDConfRes, resEDConfRes, resEDRes};
mtype:msgStatus = { success, failure, dontcare };

short DELEGATOR_PROCESS_ID	= 55;
short CAP_RECEIVER_PROCESS_ID  = 77;

short REQLENGTH  = 8;

short CAP_DELEGATOR_NODE_ID  = 433;
short CAP_RECEIVER_NODE_ID	= 655;

short CAPESETLENGTH  = 4;
short RESOURCE = 9;

short RW_PERMISSION  = 3;
short R_PERMISSION  = 1;
short NO_PERMISSION  = 0;

short INTCAPPTR = 1;
short RESCAPPTR = 1;
short INDICAPPTR = 2;

short HASH_PROCAP	 = 123;
short HASH_RECPROCAP = 234;
short HASH_INTCAP	 = 345;
short HASH_RECINTCAP = 456;
short HASH_INDICATOR_PROCAP = 567;
short HASH_INDICAP	= 678;
//short HASH_PROCAP = 567;

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
IntCapNode recIntTree[4];
ProcessCapNode delegatorCapSet[4];
ProcessCapNode recieverCapSet[4];

chan A = [1] of { mtype:msgType, mtype:msgStatus, ProcessRequestDetails} // channel from the delegator process to the intermediate controller
chan B = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap} // channel from the intermediate controller to  the delegator process
chan C = [1] of {mtype:msgType, mtype:msgStatus, IntCtrlRequestDetails} // channel from the intermediate controller to  the resouce controller
chan D = [1] of {mtype:msgType, mtype:msgStatus, ResCtrlResponseDetails} // channel from the resource controller to the intermediate controller
chan E = [1] of {mtype:msgType, mtype:msgStatus, ResCtrlResponseDetails} // channel from the resource controller to the intermediate controller
chan F = [1] of {mtype:msgType, mtype:msgStatus, ProcessCap} 

trace {
S0:
	if
	 :: A!prcEDReq,_ -> goto S1;
	fi;
S1:
	if
	 :: A?prcEDReq,_ -> goto S2;
	fi;
S2:
	if
	 :: C!intEDReq,_ -> goto S3;
	fi;
S3:
	if
	 :: C?intEDReq,_ -> goto S4;
	fi;
S4:
	if
	 :: D!resEDConfRes,success,_ -> goto S5;
	fi;
S5:
	if
	 :: D?resEDConfRes,success,_ -> goto S7;
	 :: E!resEDRes,success,_ -> goto S6;
	fi;
S6:
	if
	 :: D?resEDConfRes,success,_ -> goto S8;
	 :: E?resEDRes,success,_ -> goto S9;
	fi;
S7:
	if
	 :: B!intEDConfRes,success,_ -> goto S14;
	 :: E!resEDRes,success,_ -> goto S8;
	fi;
S8:
	if
	 :: B!intEDConfRes,success,_ -> goto S17;
	 :: E?resEDRes,success,_ -> goto S24;
	fi; 
S9:
	if
	 :: D?resEDConfRes,success,_  -> goto S24;
	 :: F!intEDRes,success,_ -> goto S10;
	fi;
S10:
	if
	 :: D?resEDConfRes,success,_ -> goto S23;
	 :: F?intEDRes,success,_ -> goto S22;
	fi;
S11:
	if
	 :: F!intEDRes,success,_ -> goto S12;
	fi; 
S12:
	if
	 :: F?intEDRes,success,_;
	fi;
S13:
	if
	 :: D?resEDConfRes,success,_ ;
	fi;
S14:
	if
	 :: B?intEDConfRes,success,_ -> goto S15;
	 :: E!resEDRes,success,_ -> goto S17;
	fi;
S15:
	if
	 :: E!resEDRes,success,_ -> goto S16;
	fi;
S16:
	if
	 :: E?resEDRes,success,_ -> goto S11;
	fi;
S17:
	if
	 :: B?intEDConfRes,success,_ -> goto S16;
	 :: E?resEDRes,success,_ -> goto S18;
	fi;
S18:
	if
	 :: B?intEDConfRes,success,_ -> goto S11;
	 :: F!intEDRes,success,_ -> goto S19;
	fi;
S19:
	if
	 :: B?intEDConfRes,success,_ -> goto S12;
	 :: F?intEDRes,success,_ -> goto S21;
	fi;
S20:
	if
	 :: B!intEDConfRes,success,_ -> goto S21;
	fi;
S21:
	if
	 :: B?intEDConfRes,success,_;
	fi;
S22:
	if
	 :: D?resEDConfRes,success,_ -> goto S20;;
	fi;
S23:
	if
	 :: B!intEDConfRes,success,_ -> goto S19;
	 :: F?intEDRes,success,_ -> goto S20;
	fi;
S24:
	if
	 :: B!intEDConfRes,success,_ -> goto S18;
	 :: F!intEDRes,success,_ -> goto S23;
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
	
	delegatorCapSet[lastIndex].proCap.intCapPtr	= INTCAPPTR;
	delegatorCapSet[lastIndex].proCap.rsrc		  = RESOURCE;
	delegatorCapSet[lastIndex].proCap.permissions = RW_PERMISSION;
	delegatorCapSet[lastIndex].proCap.procId		= DELEGATOR_PROCESS_ID;
	delegatorCapSet[lastIndex].proCap.hash		  = HASH_PROCAP;
}


inline genDelegatorProReq(reqDtails, index)
{
	reqDtails.procId					 = DELEGATOR_PROCESS_ID;
	reqDtails.capReceiverProcId	  = CAP_RECEIVER_PROCESS_ID;
	reqDtails.capReceiverNodeId	  = CAP_RECEIVER_NODE_ID;
	reqDtails.delegated_permissions = R_PERMISSION;
	reqDtails.pCap.intCapPtr		  = delegatorCapSet[index].proCap.intCapPtr;	
	reqDtails.pCap.rsrc				 = delegatorCapSet[index].proCap.rsrc;		  
	reqDtails.pCap.permissions		= delegatorCapSet[index].proCap.permissions;
	reqDtails.pCap.procId			  = delegatorCapSet[index].proCap.procId;
	reqDtails.pCap.hash				 = delegatorCapSet[index].proCap.hash;
}

inline insertDelegatorCapSet(cap, lastCapIndex)
{
	lastCapIndex++; 

	delegatorCapSet[lastCapIndex].proCap.intCapPtr = cap.intCapPtr;
	delegatorCapSet[lastCapIndex].proCap.permissions = cap.permissions;
	delegatorCapSet[lastCapIndex].proCap.length = cap.length;
	delegatorCapSet[lastCapIndex].proCap.procId = cap.procId;
	delegatorCapSet[lastCapIndex].proCap.capRecProcId = cap.capRecProcId;
	delegatorCapSet[lastCapIndex].proCap.hash = cap.hash;
}

inline insertReceiverCapSet(cap, lastCapIndex)
{
	lastCapIndex++; 

	recieverCapSet[lastCapIndex].proCap.intCapPtr = cap.intCapPtr;
	recieverCapSet[lastCapIndex].proCap.permissions = cap.permissions;
	recieverCapSet[lastCapIndex].proCap.length = cap.length;
	recieverCapSet[lastCapIndex].proCap.procId = cap.procId;
	recieverCapSet[lastCapIndex].proCap.capRecProcId = cap.capRecProcId;
	recieverCapSet[lastCapIndex].proCap.hash = cap.hash;
}

//=======================================
/* Intermediate-controller's Functions */

inline initDelelgatorICTree()
{
	delIntTree[0].valid					  = true;
	delIntTree[0].leftSibling			  = 1;
	delIntTree[0].intCap.permissions	 = NO_PERMISSION;
	delIntTree[1].parent					 = 0;
	delIntTree[1].hashProCap				= HASH_PROCAP;	
	delIntTree[1].intCap.resCapPtr		= RESCAPPTR;
	delIntTree[1].intCap.procId			= DELEGATOR_PROCESS_ID;
	delIntTree[1].intCap.capRecProcId	= 0;
	delIntTree[1].intCap.capRecNodeId	= 0;
	delIntTree[1].intCap.rsrc			  = RESOURCE;
	delIntTree[1].intCap.permissions	  = RW_PERMISSION;
	delIntTree[1].intCap.isIndicator	  = false;
	delIntTree[1].intCap.hash			  = HASH_INTCAP;
}

inline initReceiverICTree()
{
	recIntTree[0].valid					  = true;
	recIntTree[0].leftSibling			  = 0;
	recIntTree[0].intCap.permissions	  = NO_PERMISSION;
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

inline validRecIntCaps( cnt)
{
	cnt = 0;
	int i;
	for (i : 0 .. TREELENGTH - 1) {
		if 
		:: recIntTree[i].valid == true -> cnt++;
		:: else -> skip;
		fi;
	}
}

inline assertProEDReq(pReqDetails)
{
	short intCapIndex = pReqDetails.pCap.intCapPtr;
	assert(pReqDetails.pCap.isIndicator == false);
	assert(pReqDetails.pCap.rsrc == delIntTree[intCapIndex].intCap.rsrc);
	assert(pReqDetails.pCap.permissions == delIntTree[intCapIndex].intCap.permissions);
	assert(pReqDetails.pCap.procId == delIntTree[intCapIndex].intCap.procId);
	assert(pReqDetails.pCap.hash == delIntTree[intCapIndex].hashProCap);
}


inline genIntEDReq(pRequest,iRequest)
{
	short idx = pRequest.pCap.intCapPtr;

	iRequest.senderNodeId			 = CAP_DELEGATOR_NODE_ID;
	iRequest.procId					 = pRequest.procId;
	iRequest.capReceiverProcId	  = pRequest.capReceiverProcId;
	iRequest.capReceiverNodeId	  = pRequest.capReceiverNodeId;
	iRequest.delegated_permissions = pRequest.delegated_permissions;
	iRequest.intCapPtr				 = idx;

	 
	iRequest.iCap.resCapPtr	 = delIntTree[idx].intCap.resCapPtr;
	iRequest.iCap.isIndicator  = delIntTree[idx].intCap.isIndicator;
	iRequest.iCap.rsrc			= delIntTree[idx].intCap.rsrc;
	iRequest.iCap.permissions  = delIntTree[idx].intCap.permissions;
	iRequest.iCap.procId		 = delIntTree[idx].intCap.procId; 
	iRequest.iCap.capRecProcId = delIntTree[idx].intCap.capRecProcId;
	iRequest.iCap.hash			= delIntTree[idx].intCap.hash;

}

inline insertIndICaps(rResDetails, ptr)
{
	ptr = 2;
	short parent = rResDetails.delegatedICapPtr;
  
	delIntTree[ptr].parent = parent;
	delIntTree[ptr].valid = true;
	delIntTree[ptr].intCap.resCapPtr = rResDetails.iCap.resCapPtr;
	delIntTree[ptr].intCap.permissions = rResDetails.iCap.permissions;
	delIntTree[ptr].intCap.isIndicator = rResDetails.iCap.isIndicator;
	delIntTree[ptr].intCap.procId = rResDetails.iCap.procId;
	delIntTree[ptr].intCap.capRecProcId = rResDetails.iCap.capRecProcId;
	delIntTree[ptr].intCap.capRecNodeId = rResDetails.iCap.capRecNodeId;
	delIntTree[ptr].intCap.hash = rResDetails.iCap.hash;
}

inline insertRecIntCaps(rResDetails, ptr)
{
	ptr=1;

	recIntTree[ptr].parent = 0;
	recIntTree[ptr].valid = true;
	recIntTree[ptr].intCap.resCapPtr = rResDetails.iCap.resCapPtr;
	recIntTree[ptr].intCap.isIndicator = rResDetails.iCap.isIndicator;
	recIntTree[ptr].intCap.permissions = rResDetails.iCap.permissions;
	recIntTree[ptr].intCap.length = rResDetails.iCap.length;
	recIntTree[ptr].intCap.procId = rResDetails.iCap.procId;
	recIntTree[ptr].intCap.hash = rResDetails.iCap.hash;
}


inline genIndindicatorPCap(ptr, pCap)
{
	//short parent = delIntTree[ptr];

	pCap.intCapPtr = ptr;
	pCap.isIndicator = true;
	pCap.permissions = delIntTree[ptr].intCap.permissions;
	pCap.procId = delIntTree[ptr].intCap.procId; 
	pCap.capRecProcId = delIntTree[ptr].intCap.capRecProcId;
	pCap.hash = HASH_INDICATOR_PROCAP;
}

inline genReceiverProccessCap(ptr, cap)
{
	cap.intCapPtr = ptr;
	cap.isIndicator = recIntTree[ptr].intCap.isIndicator;
	cap.permissions = recIntTree[ptr].intCap.permissions;
	cap.procId = recIntTree[ptr].intCap.procId;
	cap.length = recIntTree[ptr].intCap.length;
	cap.hash = HASH_PROCAP;
}


//=======================================
/* Resource-controller's Functions */

inline initRCTree()
{
	resTree[0].valid				  = true;
	resTree[0].leftSibling		  = 1;
	resTree[0].resCap.permissions = RW_PERMISSION;
	resTree[1].valid				  = true;
	resTree[1].leftSibling		  = 0;
	resTree[1].resCap.rsrc		  = RESOURCE;
	resTree[1].resCap.permissions = RW_PERMISSION;
	resTree[1].resCap.procId		= DELEGATOR_PROCESS_ID;
	resTree[1].resCap.nodeId		= CAP_DELEGATOR_NODE_ID;
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

inline assertIntEDReq(iReqDetails)
{
	short resCapIndex = iReqDetails.iCap.resCapPtr;
	assert(iReqDetails.delegated_permissions <= resTree[resCapIndex].resCap.permissions);
	assert(iReqDetails.iCap.isIndicator == false);
	assert(iReqDetails.iCap.rsrc == resTree[resCapIndex].resCap.rsrc);
	assert(iReqDetails.iCap.permissions == resTree[resCapIndex].resCap.permissions);
	assert(iReqDetails.iCap.procId == resTree[resCapIndex].resCap.procId);
	assert(iReqDetails.iCap.hash == HASH_INTCAP);
	assert(iReqDetails.senderNodeId == resTree[resCapIndex].resCap.nodeId);
}



inline delegateResCap(iReqDetails, ptr)
{
	ptr = 2;
	short resCapPtr = iReqDetails.iCap.resCapPtr;

	resTree[ptr].valid = true;
	resTree[ptr].parent = resCapPtr;
	resTree[resCapPtr].leftSibling = ptr;

	resTree[ptr].resCap.rsrc		  = iReqDetails.iCap.rsrc;
	resTree[ptr].resCap.permissions = iReqDetails.delegated_permissions;
	resTree[ptr].resCap.procId		= iReqDetails.capReceiverProcId;
	resTree[ptr].resCap.nodeId		= iReqDetails.capReceiverNodeId;
	
}

inline genIntermediateCap( ptr, intCap)
{
	intCap.resCapPtr	 = ptr;
	intCap.isIndicator  = false;
	intCap.permissions  = resTree[ptr].resCap.permissions;
	intCap.procId		 = resTree[ptr].resCap.procId; 
	intCap.capRecProcId = resTree[ptr].resCap.procId;
	intCap.capRecNodeId = resTree[ptr].resCap.nodeId;
	intCap.hash = HASH_INDICAP;
}

inline genIndicatorCap(ptr, intIcap)
{
	short parent = resTree[ptr].parent;

	intIcap.resCapPtr	 = ptr;
	intIcap.isIndicator  = true;
	intIcap.permissions  = resTree[ptr].resCap.permissions;
	intIcap.procId		 = resTree[parent].resCap.procId; 
	intIcap.capRecProcId = resTree[ptr].resCap.procId;
	intIcap.capRecNodeId = resTree[ptr].resCap.nodeId;
	intIcap.hash = HASH_INDICAP;
}
inline genResCtrlEDConfRes(iRequest,rResponse, intCap)
{
	rResponse.procId = iRequest.procId;
	rResponse.nodeId = iRequest.senderNodeId;
	rResponse.delegatedICapPtr = iRequest.intCapPtr;

	rResponse.iCap.resCapPtr	 = intCap.resCapPtr;
	rResponse.iCap.isIndicator  = intCap.isIndicator;
	rResponse.iCap.rsrc			= intCap.rsrc;
	rResponse.iCap.permissions  = intCap.permissions;
	rResponse.iCap.procId		 = intCap.procId; 
	rResponse.iCap.capRecProcId = intCap.capRecProcId;
	rResponse.iCap.capRecNodeId = intCap.capRecNodeId;
	rResponse.iCap.hash			= intCap.hash;
}

inline genResCtrlEDRes(iRequest,rResponse, intCap)
{
	rResponse.procId = iReqDetails.capReceiverProcId;
	rResponse.nodeId = iReqDetails.capReceiverNodeId;
	rResponse.delegatedICapPtr = 0;

	rResponse.iCap.resCapPtr	 = intCap.resCapPtr;
	rResponse.iCap.isIndicator  = intCap.isIndicator;
	rResponse.iCap.rsrc			= intCap.rsrc;
	rResponse.iCap.permissions  = intCap.permissions;
	rResponse.iCap.procId		 = intCap.procId; 
	rResponse.iCap.capRecProcId = intCap.capRecProcId;
	rResponse.iCap.capRecNodeId = intCap.capRecNodeId;
	rResponse.iCap.hash			= intCap.hash;
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
	short delRCapPtr;
	mtype:msgStatus msgStts;
	IntCtrlRequestDetails iReqDetails;
	ResCtrlResponseDetails rResDetails;
	ResCtrlResponseDetails rResDetails2;
	IntermediateCap iCap;
	IntermediateCap indicatorICap;

	validResCaps(initialValidCaps);
	assert(initialValidCaps == 2);

	C?intEDReq(msgStts, iReqDetails);
	assertIntEDReq(iReqDetails);

	delegateResCap(iReqDetails, delRCapPtr);

	validResCaps(finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1);

	genIndicatorCap(delRCapPtr, indicatorICap);
	genIntermediateCap(delRCapPtr, iCap);

	genResCtrlEDConfRes(iReqDetails,rResDetails, indicatorICap);
	D!resEDConfRes(success, rResDetails); 

	genResCtrlEDRes(iReqDetails,rResDetails2, iCap);
	E!resEDRes(success, rResDetails2);

	printf("The resource controller terminated, ALL GOOD!\n");
}

active proctype Delegator_Intermediate_Controller()
{
	printf("Entering the intermediate controller (delegating side)...\n");
	initDelelgatorICTree();
	printf("Finishing initializing the intermediate controller (delegating side) ...\n");
	int initialValidCaps = 0;
	int finalValidCaps = 0;
	short iCapPtr;
	short delICapPtr;
	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDetails;
	IntCtrlRequestDetails iReqDetails;
	ResCtrlResponseDetails rResDetails;
	IntermediateCap indicatorICap;
	ProcessCap indicatorPCap;
	ProcessCap pCap;

	IntermediateCap intCap;

	validDelIntCaps(initialValidCaps);
	assert(initialValidCaps == 1);

	A?prcEDReq(msgStts, pReqDetails);
	assertProEDReq(pReqDetails);

	msgStts = dontcare;
	genIntEDReq(pReqDetails,iReqDetails);
	C!intEDReq(msgStts, iReqDetails);

	D?resEDConfRes(msgStts, rResDetails);
	assert(msgStts == success);
	assert(rResDetails.procId == DELEGATOR_PROCESS_ID);
	assert(rResDetails.nodeId == CAP_DELEGATOR_NODE_ID);
	assert(rResDetails.delegatedICapPtr == pReqDetails.pCap.intCapPtr);
	assert(rResDetails.iCap.isIndicator == true);
	assert(rResDetails.iCap.procId == DELEGATOR_PROCESS_ID);
	assert(rResDetails.iCap.capRecProcId == CAP_RECEIVER_PROCESS_ID);	
	assert(rResDetails.iCap.permissions == R_PERMISSION);
	assert(rResDetails.delegatedICapPtr == pReqDetails.pCap.intCapPtr);

	insertIndICaps(rResDetails, delICapPtr);

	validDelIntCaps(finalValidCaps);
	assert(initialValidCaps == 1);
	assert(finalValidCaps == initialValidCaps + 1);

	genIndindicatorPCap(delICapPtr, indicatorPCap);

	B!intEDConfRes(success, indicatorPCap);
	
	printf("The intermediate controller (delegator side) terminated, ALL GOOD!\n");
}

active proctype Delegator_process()
{
	printf("Entering delegator process...\n");

	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDetails;
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps;
	int finalValidCaps;

	initDelProcess(firstCapIndex, lastCapIndex);
	printf("Initializing the Delegator Process...\n");

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);
	assert(initialValidCaps == 1 );

	genDelegatorProReq(pReqDetails, 0);
	
	msgStts = dontcare;
	A!prcEDReq(msgStts, pReqDetails);

	B?intEDConfRes(msgStts, pCap);
	assert(msgStts == success);
	assert(pCap.isIndicator == true);
	assert(pCap.procId == DELEGATOR_PROCESS_ID);
	assert(pCap.capRecProcId == CAP_RECEIVER_PROCESS_ID);	
	assert(pCap.permissions == R_PERMISSION);
	
	insertDelegatorCapSet(pCap, lastCapIndex);
	noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1 );

	printf("The delegatore process terminated, ALL GOOD!\n");
}


active proctype Receiver_Intermediate_Controller()
{
	int initialValidCaps=0;
	int finalValidCaps=0;
	short iCapPtr;
	short recICapPtr;
	mtype:msgStatus msgStts;
	ResCtrlResponseDetails rResDetails;
	IntermediateCap iCap;
	ProcessCap pCap;
	 
	printf("Entering the intermediate controller (receiving side)...\n");
	initReceiverICTree();
	printf("Finishing initializing the intermediate controller (receiving side) ...\n");
	

	validRecIntCaps(initialValidCaps);
	printf("--%d", initialValidCaps);
	assert(initialValidCaps == 1);

	E?resEDRes(msgStts, rResDetails);
	assert(msgStts == success);
	assert(rResDetails.procId == CAP_RECEIVER_PROCESS_ID);
	assert(rResDetails.nodeId == CAP_RECEIVER_NODE_ID);
	assert(rResDetails.delegatedICapPtr == 0);
	assert(rResDetails.iCap.isIndicator == false);
	assert(rResDetails.iCap.procId == CAP_RECEIVER_PROCESS_ID);
	assert(rResDetails.iCap.capRecProcId == CAP_RECEIVER_PROCESS_ID);	
	assert(rResDetails.iCap.permissions == R_PERMISSION);

	insertRecIntCaps(rResDetails, recICapPtr);

	validRecIntCaps(finalValidCaps);
	assert(initialValidCaps == 1);
	assert(finalValidCaps == initialValidCaps + 1);

	genReceiverProccessCap(recICapPtr, pCap);

	F!intEDRes(success, pCap);

	printf("The intermediate controller (reciever side) terminated, ALL GOOD!\n");
}

active proctype Receiver_process()
{
	printf("Entering receiver process...\n");

	mtype:msgStatus msgStts;
	ProcessRequestDetails pReqDetails;
	ProcessCap pCap;
	int firstCapIndex = 0;
	int lastCapIndex = -1;
	int initialValidCaps;
	int finalValidCaps;

	noOfProcCaps(firstCapIndex, lastCapIndex, initialValidCaps);
	assert(initialValidCaps == 0 );

	F?intEDRes(msgStts, pCap);
	assert(msgStts == success);
	assert(pCap.isIndicator == false);
	assert(pCap.procId == CAP_RECEIVER_PROCESS_ID);
	assert(pCap.permissions == R_PERMISSION);
	
	insertReceiverCapSet(pCap, lastCapIndex);
	noOfProcCaps(firstCapIndex, lastCapIndex, finalValidCaps);
	assert(finalValidCaps == initialValidCaps + 1 );

	printf("The delegatore process terminated, ALL GOOD!\n");
}