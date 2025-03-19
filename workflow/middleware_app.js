/**
 * HTMX Examples Semantic Search API Middleware
 * 
 * This middleware handles natural language search queries by:
 * 1. Converting queries to embeddings using Google AI
 * 2. Forwarding the embeddings to the PostgREST API
 * 3. Returning the results to the client
 */

const express = require('express');
const axios = require('axios');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const winston = require('winston');
const http = require('http');
const https = require('https');
require('dotenv').config();

// Initialize logger
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'htmx-middleware' },
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({ format: winston.format.simple() })
  ],
});

// Initialize Express app
const app = express();
app.use(express.json());

// Configuration from environment variables
const PORT = process.env.MIDDLEWARE_PORT || 3000;
const POSTGREST_URL = process.env.POSTGREST_URL || 'http://127.0.0.1:3001';
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

// Check if Google API key is available
if (!GOOGLE_API_KEY) {
  logger.error('GOOGLE_API_KEY is not set in environment variables');
  process.exit(1);
}

// Force IPv4 for all axios requests
const httpAgent = new http.Agent({ family: 4 });
const httpsAgent = new https.Agent({ family: 4 });

// Create an axios instance with IPv4 configuration
const axiosIPv4 = axios.create({
  httpAgent,
  httpsAgent,
  timeout: 10000 // 10 second timeout
});

// Helper function to ensure URLs use IPv4
function ensureIPv4Url(url) {
  return url.replace(/localhost/g, '127.0.0.1');
}

// Initialize Google AI client
const genAI = new GoogleGenerativeAI(GOOGLE_API_KEY);

/**
 * Generate an embedding vector for a text query
 * @param {string} text - The text to embed
 * @returns {Promise<number[]>} - The embedding vector
 */
async function generateEmbedding(text) {
  try {
    logger.info(`Generating embedding for query: "${text}"`);
    
    // Create embedding model
    const model = genAI.getGenerativeModel({ model: "models/text-embedding-004" });
    
    // Generate embedding
    const embeddingResult = await model.embedContent({
      content: {
        parts: [
          { text }
        ],
      },
      taskType: "RETRIEVAL_QUERY"
    });
    
    const embedding = embeddingResult.embedding.values;
    logger.info(`Generated embedding with ${embedding.length} dimensions`);
    
    return embedding;
  } catch (error) {
    logger.error('Error generating embedding:', error);
    throw new Error(`Embedding generation failed: ${error.message}`);
  }
}

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Basic search endpoint
app.get('/api/search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    const limit = parseInt(req.query.limit || '5');
    const embeddingType = req.query.embedding_type || 'content';
    const category = req.query.category || null;
    const complexity = req.query.complexity || null;
    
    logger.info('Processing search query:', { query, embeddingType, limit });
    
    // Generate embedding
    const embedding = await generateEmbedding(query);
    
    // Call PostgREST with the embedding using IPv4
    const postUrl = `${ensureIPv4Url(POSTGREST_URL)}/rpc/vector_search`;
    logger.info(`Making request to: ${postUrl}`);
    
    const response = await axiosIPv4.post(postUrl, {
      query_embedding: embedding,
      embedding_type: embeddingType,
      result_limit: limit,
      category_filter: category,
      complexity_filter: complexity
    });
    
    res.json(response.data);
  } catch (error) {
    logger.error('Search error:', error);
    res.status(500).json({ 
      error: 'Search failed', 
      details: error.message 
    });
  }
});

// Multi-search endpoint
app.get('/api/multi-search', async (req, res) => {
  try {
    const query = req.query.q;
    if (!query) {
      return res.status(400).json({ error: 'Query parameter "q" is required' });
    }
    
    const limit = parseInt(req.query.limit || '5');
    const category = req.query.category || null;
    const complexity = req.query.complexity || null;
    
    logger.info('Processing multi-search query:', { query, limit });
    
    // Generate embedding
    const embedding = await generateEmbedding(query);
    
    // Call PostgREST with the embedding using IPv4
    const postUrl = `${ensureIPv4Url(POSTGREST_URL)}/rpc/multi_vector_search`;
    logger.info(`Making request to: ${postUrl}`);
    
    const response = await axiosIPv4.post(postUrl, {
      query_embedding: embedding,
      result_limit: limit,
      category_filter: category,
      complexity_filter: complexity
    });
    
    res.json(response.data);
  } catch (error) {
    logger.error('Multi-search error:', error);
    res.status(500).json({ 
      error: 'Multi-search failed', 
      details: error.message 
    });
  }
});

// Similar examples search endpoint
app.get('/api/similar', async (req, res) => {
  try {
    const exampleId = req.query.id;
    if (!exampleId) {
      return res.status(400).json({ error: 'Query parameter "id" is required' });
    }
    
    const limit = parseInt(req.query.limit || '5');
    const embeddingType = req.query.embedding_type || 'content';
    const category = req.query.category || null;
    const complexity = req.query.complexity || null;
    
    logger.info('Processing similar examples query:', { exampleId, embeddingType, limit });
    
    // Call PostgREST to find similar examples using IPv4
    const postUrl = `${ensureIPv4Url(POSTGREST_URL)}/rpc/find_similar_examples`;
    logger.info(`Making request to: ${postUrl}`);
    
    const response = await axiosIPv4.post(postUrl, {
      example_id: exampleId,
      embedding_type: embeddingType,
      result_limit: limit,
      category_filter: category,
      complexity_filter: complexity
    });
    
    res.json(response.data);
  } catch (error) {
    logger.error('Similar examples error:', error);
    res.status(500).json({ 
      error: 'Similar examples search failed', 
      details: error.message 
    });
  }
});

// Forward all other requests to PostgREST
app.all('/direct/*', async (req, res) => {
  try {
    // Prepare headers but remove host
    const headers = { ...req.headers };
    delete headers.host;
    
    // Forward to PostgREST, removing the /direct prefix
    const targetUrl = `${ensureIPv4Url(POSTGREST_URL)}${req.url.replace(/^\/direct/, '')}`;
    logger.info(`Proxying request to: ${targetUrl}`);
    
    const response = await axiosIPv4({
      method: req.method,
      url: targetUrl,
      data: req.body,
      headers: headers,
      responseType: 'stream',
    });
    
    // Forward response headers
    Object.entries(response.headers).forEach(([key, value]) => {
      res.set(key, value);
    });
    
    // Stream response data
    response.data.pipe(res);
  } catch (error) {
    logger.error('PostgREST proxy error:', error);
    res.status(error.response?.status || 500).json(
      error.response?.data || { error: 'Proxy request failed' }
    );
  }
});

// Start the server
app.listen(PORT, () => {
  logger.info(`Middleware listening on port ${PORT}`);
  logger.info(`Connected to PostgREST at ${ensureIPv4Url(POSTGREST_URL)}`);
}); 