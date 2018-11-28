--EXEC [Analytics_WS].ks.BankInfoAggSP

--SELECT a.* 
--INTO #BankInfoAggTemp 
--FROM 
--	OPENROWSET
--		(
--             'SQLNCLI'
--           , 'Server=s26;Trusted_Connection=yes;'
--           , 'EXEC Analytics_WS.ks.BankInfoAggSP'
--         )	a




--select * from analytics_ws.ks.vw_BankInfoAgg



select o_vw.OppId
     , cr.Id as [CR ID]
     , o_vw.Credit_Sub_Date__c
     --, o_vw.StageName
	 --, crc.Final_Outcome__c
	 --, o_vw.eNoah_Complete_Date__c
	 --, o_vw.Lender_Account_Name
	 --, o_vw.OppName

	 , 1 as [Credit Submission Flag]

	 , case when o_vw.Lender_Account_Name is null and o_vw.StageName in ('Pre-Qual MCA','Lender Pend Info','Internal Pend Info') then 1 else 0 end as Pending_Submission_Flag

	 , case when o_vw.Production_Channel = 'WC Direct Sales' then 'Direct'
			when o_vw.Production_Channel = 'WC Broker Sales' then 'Broker'
			when o_vw.Production_Channel like '%renewal%' then 'Renewal'
			else 'Other' 
			end as [Production Channel]

	 , o_vw.OppType

	 , CASE WHEN cd.WC_Decision_Recommendation__c IN ('NF Auto Decline', 'Auto Decline') THEN 'NF/Auto Decline' 
		   WHEN cd.Model_Grade__c IS NOT NULL THEN cd.Model_Grade__c
		   WHEN crc.Final_Outcome__c = 'Auto Declined' THEN 'NF/Auto Decline' 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '12' THEN 'A+' 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '10' THEN 'A-' 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '9' THEN 'B' 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '8' THEN 'C' 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = 'Model Review' THEN 'D' 
		   WHEN cd.Model_Grade__c IS NULL AND coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) IS NULL THEN 'No Grade' 
		   END AS [Model Risk Group]


	 , CASE WHEN cd.WC_Decision_Recommendation__c IN ('NF Auto Decline', 'Auto Decline') THEN 0
		   WHEN cd.Model_Grade__c IS NOT NULL THEN 1
		   WHEN crc.Final_Outcome__c = 'Auto Declined' THEN 0
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '12' THEN 1 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '10' THEN 1
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '9' THEN 1 
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = '8' THEN 1
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = 'Model Review' and o_vw.Production_Channel = 'WC Direct Sales' THEN 1
		   WHEN coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) = 'Model Review' and o_vw.Production_Channel = 'WC Broker Sales' THEN 0 
		   WHEN cd.Model_Grade__c IS NULL AND coalesce(cd.Model_Risk_Classification__c, dm.DelMarScore) IS NULL THEN 0
		   END AS [NF Approvable Sub Flag]


	 --, coalesce(coalesce(o_vw.Internal_Credit_Analyst_FullName,o_vw.Credit_Analyst_FullName),o_vw.Commercial_Analyst_FullName) as [Credit Analyst]

	 , case when (o_vw.Approval_Date__c is not null and o_vw.Lender_Account_Name like 'National Funding%') 
	             OR o_vw.NF_Withdrawn_Date is not null
			then 1
			else 0
			end as [NF Approval Flag]

	 --, case when o_vw.Approval_Date__c is not null and o_vw.Lender_Account_Name like 'National Funding%'
		--	 then o_vw.Approval_Date__c 
		--	 else null end as [NF Approval Date]


	 , case when o_vw.APPROVAL_DATE__c is not null and o_vw.Lender_Account_Name like 'National Funding%' then cr.Max_Term__c
	        else NULL 
			end as [NF Analyst Approval Term] 
	 
	 , case when o_vw.APPROVAL_DATE__c is not null and o_vw.Lender_Account_Name like 'National Funding%' then cr.Max_Approval_Amount__c
	        else NULL 
			end as [NF Analyst Approval Amount]

	 , case when o_vw.NF_Withdrawn_Date is not null then 1 else 0 end as [NF Withdrawn Flag]

	 , case when o_vw.Approval_Date__c is not null and o_vw.Lender_Account_Name is not null
	        then 1 else 0 
			end as [Approval Flag]

	 , case when o_vw.StageName = 'Funded' 
	         and o_vw.Fund_Date__c is not null 
			 and o_vw.Lender_Account_Name like 'National Funding%' 
			then 1 else 0 end as [NF Funded Flag]


	 , case when o_vw.StageName = 'Funded' 
	      and o_vw.Fund_Date__c is not null 
	  	  and o_vw.Lender_Account_Name like 'National Funding%'
	  	  and lv.lease_term_date is not null 
	  	  and (l.LUF14_Internal_Funding_Status = 'Loan Write-off' or l.ReasonCode = 'WRITEOFF')
	    then 1 
		else 0 
		end as [NF Charge Off Flag]


	 , cr.Average_of_Average_Daily_Balance__c as [CR ADB]
	 , cr.Max_FICO_Score__c as [CR Max FICO]
	 , cr.Min_FICO_Score__c as [CR Min FICO]
	 , cr.CreatedDate as [CR Created Date]
     , cr.Time_In_Business__c as [CR TIB]
	 , o.Years_In_Business__c as [CR YIB]
	 , cr.Business_Start_Date__c as [CR Business Start Date]
	 , cr.Annual_Revenue__c as [CR Annual Revenue]
	 , cr.Home_Based_Business__c as [CR Home Based Business Flag]
	 , left(cr.SIC_Code__c, 4) as [CR SIC Code]
	 , left(cr.SIC_Code__c, 2) as [CR SIC Code 2 Digit]

	 , sic.Category__c as [SIC Category]
     
	 , coalesce(o_vw.Decline_Reasons__c,o_vw.Broker_Decline_Reasons__c) as Decline_Reasons
	 	 
	 , cd.Platinum_Term_Reason__c
	 , o_vw.Data_Update_TS

	 , case when o_vw.Credit_Sub_Date__c < '2018-10-04' then cd.Model_Approval_Probability__c 
	        else coalesce(MD.delMar_V2_appr_prob__c, dm.Model_Approval_Probability__c)
			end as [Del Mar V2 Approval Prob]
	 
	 --, case when o_vw.Credit_Sub_Date__c < '2018-10-04' then cd.Model_Approval_Probability__c 
	 --       else coalesce(MD.delMar_V2_appr_prob__c, dm.Model_Approval_Probability__c)
		--	end as [Del Mar V2 Approval Prob]

	 --, case when o_vw.Credit_Sub_Date__c < '2018-10-04' then cd.Model_Approval_Probability__c 
	 --       else coalesce(MD.delMar_V2_appr_prob__c, dm.Model_Approval_Probability__c)
		--	end as [Del Mar V2 Approval Prob]

	 --, case when o_vw.Credit_Sub_Date__c < '2018-10-04' then cd.Model_Approval_Probability__c 
	 --       else coalesce(MD.delMar_V2_appr_prob__c, dm.Model_Approval_Probability__c)
		--	end as [Del Mar V2 Approval Prob]


	 , MD.delMar_V2_appr_score__c
	 , MD.delMar_V2_co_prob__c
	 , MD.delMar_V2_co_score__c
	 , MD.delMar_V2_Score__c
	 , MD.delMar_V2_Score_raw__c
	 , MD.delMar_V2_RiskClass__c
	 , MD.delMar_V3_appr_prob__c
	 , MD.delMar_V3_appr_score__c
	 , MD.delMar_V3_co_prob__c
	 , MD.delMar_V3_co_score__c
	 , MD.delMar_V3_RiskClass__c

	 , cd.Model_Decision_Score__c

	 , bia.*


from Analytics_DWH.dbo.Opportunity_All_VW o_vw
    inner join Salesforce_Repl.dbo.Opportunity o
		on o_vw.OppId = o.Id
	left join Analytics_DWH.dbo.LP_LoanAgg l
		on o_vw.Merchant_Number__c = l.Lease_Num
	left join Analytics_DWH.dbo.LP_Sub_LPlusLeaseVW lv
		on o_vw.Merchant_Number__c = lv.Lease_Num
	left join Salesforce_Repl.dbo.WC_Credit_Decision__c cd
		on o_vw.WC_Credit_Decision_Record__c = cd.Id
	left join Salesforce_Repl.dbo.Credit_Review__c cr
		on o_vw.Best_CreditReviewId = cr.Id
	left join Salesforce_Repl.dbo.NF_SIC_4__c sic
		on o_vw.SIC_Code__c = sic.SIC_Code__c
	left join Analytics_DWH.dbo.LoanAgg_PayoffInterest pint
		on l.lease_num = pint.lease_num
	left join [Salesforce_Repl].[dbo].[Credit_Review_Controller__c] as CRC
		on CRC.Credit_Review__c = CR.Id

	left join Salesforce_Repl.dbo.Model_Decision__c MD
		on MD.WC_Credit_Decision__c = cd.Id

    left join
            (
            select
            cd.Credit_Review__c
            ,DelMarScore = cd.Model_Risk_Classification__c
			,cd.Model_Approval_Probability__c
            ,cd.CreatedDate
            ,cr.Opportunity__c
            ,latestflag = case when ROW_NUMBER() over (partition by cr.Opportunity__c order by cd.CreatedDate DESC) = 1
                            then 1 else 0 end
            from Salesforce_Repl.dbo.WC_Credit_Decision__c as cd
            left join Salesforce_Repl.dbo.Credit_Review__c as cr
                on cd.Credit_Review__c = cr.Id
            where cd.CreatedDate >= '2018-10-01'
            and Model_Risk_Classification__c is not null
            )
        as dm
            on dm.Opportunity__c = o_vw.OppId
                and dm.latestflag=1

	left join analytics_ws.ks.vw_BankInfoAgg bia
		on bia.[Opportunity ID] = o_vw.OppId
	

where 

	    o_vw.Production_Channel LIKE '%WC%'
    AND o_vw.Best_CreditReviewId is not null
	AND o_vw.Credit_Sub_Date__c >= '2017-01-01'
	

	

order by o_vw.Credit_Sub_Date__c desc

