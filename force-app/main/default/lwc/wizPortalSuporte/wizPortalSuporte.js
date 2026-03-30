import { LightningElement, api, track } from 'lwc';
import wizLogoUrl from '@salesforce/resourceUrl/wizLogo';

export default class WizPortalSuporte extends LightningElement {

    /** API name do flow — configurável no Experience Builder */
    @api flowApiName = 'PedidoSuporteOuInteracao';

    @track flowCompleted = false;
    @track flowError     = false;

    get logoUrl() {
        return wizLogoUrl;
    }

    get currentYear() {
        return new Date().getFullYear();
    }

    handleStatusChange(event) {
        const status = event.detail.status;

        if (status === 'FINISHED' || status === 'FINISHED_SCREEN') {
            this.flowCompleted = true;
            this.flowError     = false;
        }

        if (status === 'ERROR') {
            this.flowError     = true;
            this.flowCompleted = false;
        }
    }

    handleRestart() {
        this.flowCompleted = false;
        this.flowError     = false;
    }
}
