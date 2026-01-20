/**
 * Created by Chris Gibson on 2/14/2023.
 */

import {LightningElement, wire} from 'lwc';
import getFairShareData from '@salesforce/apex/FairShareManagementHelper.getFairShareInformation';
import getDesignationRecord from '@salesforce/apex/FairShareManagementHelper.getDesignation';
import getMemDesignationId from '@salesforce/apex/FairShareManagementHelper.getMemDesignationId';
import getPSTDesignationId from '@salesforce/apex/FairShareManagementHelper.getPSTDesignationId';
import createNewFairShares from '@salesforce/apex/FairShareManagementHelper.createFairSharesFromLastFY';
import createNewZeroFairShare from '@salesforce/apex/FairShareManagementHelper.createZeroDollarFairShare';
import createInvoices from '@salesforce/apex/FairShareManagementHelper.createInvoices';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class FairShareManagement extends LightningElement {

    fairShareWrapper;
    isLoading = false;

    chosenPreviousFiscalYear;
    chosenCurrentFiscalYear;

    memDesignationId = 'a02Ho00002kTfmCIAS';
    pstDesignationId = 'a02Ho00002kTfmDIAS';


    membershipAmount = 0;
    pstAmount = 150;

    memTypeSelected;

    currentFiscalYearLabel;

    configurationsChosen = false;

    /// *IMPORTANT *
    // value should be the end year value of FY
    fiscalYears = [
        {label: '2022-2023', value: 2023},
        {label: '2023-2024', value: 2024},
        {label: '2024-2025', value: 2025},
        {label: '2025-2026', value: 2026},
        {label: '2026-2027', value: 2027},
        {label: '2027-2028', value: 2028},
    ];

    memberTypes = [
        {label: '--NONE--', value: ''},
        {label: 'Non-Member', value: 'Non-Member'},
        {label: 'Regular', value: 'Regular'},
        {label: 'Complimentary', value: 'Complimentary'},
        {label: 'Complimentary - Conversion', value: 'Complimentary - Conversion'},
        {label: 'Complimentary - Marriage', value: 'Complimentary - Marriage'},
        {label: 'HUC', value: 'HUC'},
        {label: 'Special Circumstances', value: 'Special Circumstances'},
        {label: 'Out of Town', value: 'Out of Town'},
        {label: 'Staff', value: 'Staff'},
        {label: 'YAC', value: 'YAC'},
        {label: 'YAC - Complimentary', value: 'YAC - Complimentary'},
        {label: 'Non-member Religious School', value: 'Non-member Religious School'},
        {label: 'Prospective', value: 'Prospective'},
        {label: 'Prospective - Conversion', value: 'Prospective - Conversion'},
        {label: 'Prospective - no longer', value: 'Prospective - no longer'},
        {label: 'Resigned', value: 'Resigned'},
        {label: 'Suspended', value: 'Suspended'},
        {label: 'Home Base', value: 'Home Base'},
    ];

    @wire(getMemDesignationId)
    wiredMem({error, data}){
        if(data){
            this.memDesignationId = data;
            console.log('MEMBER SHIP DESIGNATION ID: ' + this.memDesignationId);
        }
        if(error){
            console.error('ERROR retrieving Mem Designation Id');
        }
    }

    @wire(getPSTDesignationId)
    wiredPST({error, data}){
        if(data){
            this.pstDesignationId = data;
        }
        if(error){
            console.error('ERROR retrieving PST Designation Id');
        }
    }


    getFairShareRecords(currentFiscalYear, previousFiscalYear, memType) {
        this.fairShareWrapper = null;
        getFairShareData({
            currentFiscalYear: currentFiscalYear,
            previousFiscalYear: previousFiscalYear,
            membershipType: memType
        }).then(result => {
            if (result) {
                this.fairShareWrapper = result;
            }
        })
    }

    runFairShareCreation() {
        if (!this.memTypeSelected) {
            alert('You must select a membership type before using this button');
        }

        let response = confirm('Are you sure you want to create a Fair Share record for all Accounts that don\'t have one? ' +
            'Any families that already have existing Fair Share records for the current year will not be updated/created.');
        if (response)
            createNewFairShares({
                currentFY: this.chosenCurrentFiscalYear,
                previousFY: this.chosenPreviousFiscalYear,
                fsWrap: this.fairShareWrapper,
                membershipAmount: this.membershipAmount,
                pstAmount: this.pstAmount
            }).then(result => {
                const toastEvent = new ShowToastEvent({
                    "title": "SUCCESS!",
                    "message": "The new Fair Share records were created successfully",
                    "variant": "success"
                });
                this.dispatchEvent(toastEvent);
            }).catch(error => {
                console.log(JSON.stringify(error));
                console.log(JSON.stringify(error.body.pageErrors));
                const toastEvent = new ShowToastEvent({
                    "title": "ERROR!",
                    "message": error.body.pageErrors,
                    "variant": "error"
                });
                this.dispatchEvent(toastEvent);
            })
    }

    runFairShareUpdate() {
        let response = confirm('Are you sure you want to update 0$ fair share records for this year based on last year\'s total?');
        if (response)
            createNewZeroFairShare({
                currentFY: this.chosenCurrentFiscalYear,
                fsWrap: this.fairShareWrapper
            }).then(result => {
                const toastEvent = new ShowToastEvent({
                    "title": "SUCCESS!",
                    "message": "The new Fair Share records were created successfully",
                    "variant": "success"
                });
                this.dispatchEvent(toastEvent);
            }).catch(error => {
                console.log(JSON.stringify(error));
                console.log(JSON.stringify(error.body.pageErrors));
                const toastEvent = new ShowToastEvent({
                    "title": "ERROR!",
                    "message": error.body.pageErrors,
                    "variant": "error"
                });
                this.dispatchEvent(toastEvent);
            })
    }

    async runInvoiceCreation() {
        let response = confirm('Are you sure you want to create invoices for all current fiscal year fair share records?');
        if (response) {
            this.isLoading = true;
            let hadError = false;
            let errorMessage = '';
            let chunkSize = 75;
            console.log(this.fairShareWrapper);
            console.log(this.fairShareWrapper.FairSharesWithoutInvoices);
            for (let i = 0; i < this.fairShareWrapper.FairSharesWithoutInvoices.length; i += chunkSize) {
                let fsToPass = this.fairShareWrapper.FairSharesWithoutInvoices.slice(i, i + chunkSize);
                console.log(fsToPass);
                console.log(fsToPass.length);
                let result = await createInvoices({
                    fs: fsToPass,
                    membershipDesignationId: this.memDesignationId,
                    pstDesignationId: this.pstDesignationId
                }).catch(error => {
                    console.log(JSON.stringify(error));
                    console.log(JSON.stringify(error.body.pageErrors));
                    hadError = true;
                });
            }

            this.isLoading = false;
            if (!hadError) {
                const toastEvent = new ShowToastEvent({
                    "title": "SUCCESS!",
                    "message": "Invoices have now been created. Please refresh this screen to see updated totals.",
                    "variant": "success"
                });
                this.dispatchEvent(toastEvent);
            } else {
                const toastEvent = new ShowToastEvent({
                    "title": "ERROR!",
                    "message": error.body.pageErrors + ' Please refresh the page before trying again.',
                    "variant": "error"
                });
                this.dispatchEvent(toastEvent);
            }

        }
    }

    inputOnChangeHandler(event) {
        console.log(event.target.name);
        if (event.target.name === 'currentFiscalYear') {
            this.chosenCurrentFiscalYearVal = parseInt(event.detail.value);
            this.chosenCurrentFiscalYear = (this.chosenCurrentFiscalYearVal - 1) + '-' + this.chosenCurrentFiscalYearVal;
            this.chosenPreviousFiscalYear = (this.chosenCurrentFiscalYearVal - 2) + '-' + (this.chosenCurrentFiscalYearVal - 1);
            console.log(JSON.stringify(event.detail));
            this.runConfigurationSelectionCheck();
        } else if (event.target.name === 'memDesignationName') {
            this.memDesignationId = event.target.value;
            console.log(this.memDesignationId);
        } else if (event.target.name === 'secDesignationName') {
            this.pstDesignationId = event.target.value;
            console.log(this.pstDesignationId);
        } else if (event.target.name === 'memAmount') {
            this.membershipAmount = event.target.value;
        } else if (event.target.name === 'pstAmount') {
            this.pstAmount = event.target.value;
        } else if (event.target.name === 'membershipType') {
            this.memTypeSelected = event.detail.value;
            this.runConfigurationSelectionCheck();
        }
    }

    runConfigurationSelectionCheck() {
        if (this.chosenCurrentFiscalYear === undefined) {
            let divblock = this.template.querySelector('[data-id="divblock"]');
            if (divblock) {
                this.template.querySelector('[data-id="divblock"]').className = 'class1';
            }
        }
        if (this.memTypeSelected === undefined) {

        }

        if (this.memTypeSelected !== true && this.chosenCurrentFiscalYear !== undefined) {
            this.configurationsChosen = true;
            this.getFairShareRecords(this.chosenCurrentFiscalYear, this.chosenPreviousFiscalYear, this.memTypeSelected);

        }

    }

}