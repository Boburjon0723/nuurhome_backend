const { createClient } = require('redis');

let redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

// Railway provides REDISHOST, REDISPORT if not full REDIS_URL
if (redisUrl && !redisUrl.startsWith('redis://')) {
    redisUrl = `redis://${redisUrl}`;
}

const redisClient = createClient({
    url: redisUrl
});

redisClient.on('error', (err) => {
    console.log('Redis Client Error:', err.message);
});

redisClient.on('connect', () => {
    console.log('Redis connected successfully');
});

(async () => {
    try {
        await redisClient.connect();
    } catch (err) {
        console.error('Failed to connect to Redis, but server will continue:', err.message);
    }
})();

module.exports = redisClient;
