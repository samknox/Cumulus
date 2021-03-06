/*
    Copyright (c) 2014, Salesforce.com Foundation
    All rights reserved.
    
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
    
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Salesforce.com Foundation nor the names of
      its contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
    COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, 
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER 
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGE.
*/
/**
* @author Salesforce.com Foundation
* @date 2014
* @group Rollups
* @group-content ../../ApexDocContent/Rollups.htm
* @description Batch class for opportunity account rollups. 
*/
public with sharing class RLLP_OppAccRollup_BATCH implements Database.Batchable<SObject>, UTIL_MasterSchedulableHelper.UTIL_IRecurring {
		
    /*******************************************************************************************************
    * @description Implementation of UTIL_MasterSchedulableHelper.UTIL_IRecurring, to allow nightly 
    * scheduling. Attempts to start allocations rollup batch job.
    * @return Boolean Whether the batch job started successfully. 
    ********************************************************************************************************/
	public Boolean executeReturnStatus() {
        if(UTIL_JobScheduler.canRunBatch()) {
        	Savepoint sp = Database.setSavepoint();
        	try {
                Database.executeBatch(this);
                return true;
        	} catch(Exception e) {
	            Database.rollback(sp);
	            ERR_Handler.processError(e, ERR_Handler_API.Context.RLLP);
	        }
        }
        return false;
    }
    
    /*******************************************************************************************************
    * @description Batch start method, instantiates RLLP_OppRollup_UTIL and builds query for account rollups.
    ********************************************************************************************************/
	public database.Querylocator start(Database.BatchableContext bc) {
        RLLP_OppRollup_UTIL oppRollupUtil = new RLLP_OppRollup_UTIL();
        String acctQuery = oppRollupUtil.buildAccountQuery();        
        return Database.getQueryLocator(acctQuery);
    }
    
    /*******************************************************************************************************
    * @description Batch execute method, instantiates RLLP_OppRollup_UTIL and runs rollups for current 
    * batch of accounts.
    ********************************************************************************************************/
    public void execute(Database.BatchableContext bc, List<Account> result) {       
        // NOTE: we don't capture exception and log errors here, because if we don't let the 
        // exception percolate up the call stack, then the batch will think it all succeeded.
        // but if we were to log it, and then propagate the exception, the transaction will 
        // get rolled back, and the logging will be erased!
        RLLP_OppRollup oppRoller = new RLLP_OppRollup();        
        oppRoller.RollupAccounts(new Map<id, Account>((List<Account>)result));    
    }

    /*******************************************************************************************************
    * @description Batch finish method, does nothing.
    ********************************************************************************************************/
    public void finish(Database.BatchableContext bc) {}
}