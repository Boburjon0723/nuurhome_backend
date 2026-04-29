const prisma = require('../lib/prisma');
const redisClient = require('../config/redis');

const CACHE_KEY_SETTINGS = 'all_settings';

exports.getAllSettings = async (req, res) => {
  try {
    // 1. Try Cache
    try {
      const cached = await redisClient.get(CACHE_KEY_SETTINGS);
      if (cached) return res.json({ success: true, settings: JSON.parse(cached) });
    } catch (err) { console.error('Redis Get Settings Error:', err); }

    const settingsArr = await prisma.siteSetting.findMany();
    const settings = {};
    settingsArr.forEach(s => {
      settings[s.key] = s.value;
    });
    
    // 2. Set Cache
    try {
      await redisClient.setEx(CACHE_KEY_SETTINGS, 86400, JSON.stringify(settings)); // 24 hours
    } catch (err) { console.error('Redis Set Settings Error:', err); }

    res.json({ success: true, settings });
  } catch (error) {
    console.error('Get Settings Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateSetting = async (req, res) => {
  const { key, value } = req.body;
  try {
    const setting = await prisma.siteSetting.upsert({
      where: { key },
      update: { value },
      create: { key, value }
    });

    // Invalidate Cache
    try {
      await redisClient.del(CACHE_KEY_SETTINGS);
    } catch (err) { console.error('Redis Del Settings Error:', err); }

    res.json({ success: true, setting });
  } catch (error) {
    console.error('Update Setting Error:', error);
    res.status(500).json({ success: false, error: error.message });
  }
};
