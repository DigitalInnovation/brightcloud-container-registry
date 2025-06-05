import { DefaultAzureCredential, WorkloadIdentityCredential } from '@azure/identity';
import { TokenCredential } from '@azure/core-auth';
import * as core from '@actions/core';

export interface AzureAuthConfig {
  clientId: string;
  tenantId: string;
  subscriptionId: string;
}

export class AzureAuthenticator {
  async authenticate(config: AzureAuthConfig): Promise<TokenCredential> {
    try {
      // In GitHub Actions with OIDC, we prefer WorkloadIdentityCredential
      if (process.env.ACTIONS_ID_TOKEN_REQUEST_URL && process.env.ACTIONS_ID_TOKEN_REQUEST_TOKEN) {
        core.info('🔐 Using GitHub Actions OIDC for Azure authentication');
        
        const credential = new WorkloadIdentityCredential({
          tenantId: config.tenantId,
          clientId: config.clientId,
          tokenFilePath: process.env.AZURE_FEDERATED_TOKEN_FILE
        });

        // Test the credential
        await this.testCredential(credential);
        return credential;
      }

      // Fallback to DefaultAzureCredential
      core.info('🔐 Using DefaultAzureCredential for Azure authentication');
      const credential = new DefaultAzureCredential();
      
      // Test the credential
      await this.testCredential(credential);
      return credential;

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new Error(`Azure authentication failed: ${errorMessage}`);
    }
  }

  private async testCredential(credential: TokenCredential): Promise<void> {
    try {
      // Test credential by requesting a token for Azure Resource Manager
      const token = await credential.getToken('https://management.azure.com/.default');
      
      if (!token || !token.token) {
        throw new Error('Failed to obtain access token');
      }

      core.info('✅ Azure credential validated successfully');
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      throw new Error(`Credential validation failed: ${errorMessage}`);
    }
  }
}