#!/usr/bin/env node

/**
 * Mock n8n License Server
 * 
 * This creates a local license server that generates valid license certificates
 * for n8n without requiring the official n8n license server.
 * 
 * Usage:
 * 1. Run this server: node mock-license-server.js
 * 2. Set environment variable: N8N_LICENSE_SERVER_URL=http://localhost:3001
 * 3. Use any activation key in n8n UI
 */

const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json());

// Mock license certificate template
const generateLicenseCertificate = (activationKey, instanceId) => {
  const now = new Date();
  const expiryDate = new Date(now.getTime() + (365 * 24 * 60 * 60 * 1000)); // 1 year from now
  
  const certificate = {
    version: "1.0",
    issuer: "Mock License Server",
    subject: instanceId,
    activationKey: activationKey,
    issuedAt: now.toISOString(),
    expiresAt: expiryDate.toISOString(),
    features: {
      // Enable all enterprise features
      "feat:sharing": true,
      "feat:ldap": true,
      "feat:saml": true,
      "feat:logStreaming": true,
      "feat:advancedExecutionFilters": true,
      "feat:variables": true,
      "feat:sourceControl": true,
      "feat:auditLogs": true,
      "feat:externalSecrets": true,
      "feat:debugInEditor": true,
      "feat:binaryDataS3": true,
      "feat:workflowHistory": true,
      "feat:workerView": true,
      "feat:advancedPermissions": true,
      "feat:apiKeyScopes": true,
      "feat:aiAssistant": true,
      "feat:askAi": true,
      "feat:aiCredits": true
    },
    quotas: {
      "quota:users": 999999,
      "quota:activeWorkflows": 999999,
      "quota:maxVariables": 999999,
      "quota:aiCredits": 999999,
      "quota:workflowHistoryPrune": 999999,
      "quota:insights:maxHistoryDays": 999999,
      "quota:insights:retention:maxAgeDays": 999999,
      "quota:maxWorkflowsWithEvaluations": 999999
    },
    planId: "enterprise-unlimited",
    planName: "Enterprise Unlimited (Mock)"
  };
  
  // Sign the certificate (in real implementation, this would be cryptographically signed)
  const signature = crypto
    .createHmac('sha256', 'mock-secret-key')
    .update(JSON.stringify(certificate))
    .digest('hex');
  
  return {
    certificate: Buffer.from(JSON.stringify(certificate)).toString('base64'),
    signature: signature
  };
};

// License activation endpoint
app.post('/license/activate', (req, res) => {
  const { activationKey } = req.body;
  const instanceId = req.headers['x-instance-id'] || 'mock-instance';
  
  console.log(`License activation request:`, {
    activationKey,
    instanceId,
    timestamp: new Date().toISOString()
  });
  
  if (!activationKey) {
    return res.status(400).json({
      error: 'SCHEMA_VALIDATION',
      message: 'Activation key is required'
    });
  }
  
  // Generate mock license certificate
  const license = generateLicenseCertificate(activationKey, instanceId);
  
  // Return the license certificate in the format expected by n8n
  res.json({
    success: true,
    license: license.certificate,
    signature: license.signature,
    message: 'License activated successfully'
  });
});

// License renewal endpoint
app.post('/license/renew', (req, res) => {
  const instanceId = req.headers['x-instance-id'] || 'mock-instance';
  
  console.log(`License renewal request:`, {
    instanceId,
    timestamp: new Date().toISOString()
  });
  
  // Generate renewed license certificate
  const license = generateLicenseCertificate('renewed-key', instanceId);
  
  res.json({
    success: true,
    license: license.certificate,
    signature: license.signature,
    message: 'License renewed successfully'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    service: 'Mock n8n License Server',
    timestamp: new Date().toISOString()
  });
});

// Start the server
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => {
  console.log(`🚀 Mock n8n License Server running on port ${PORT}`);
  console.log(`📝 To use with n8n, set: N8N_LICENSE_SERVER_URL=http://localhost:${PORT}`);
  console.log(`🔑 Any activation key will work with this mock server`);
});
