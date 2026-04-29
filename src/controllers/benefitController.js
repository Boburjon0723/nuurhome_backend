const prisma = require('../lib/prisma');
const redisClient = require('../config/redis');

const CACHE_KEY_BENEFITS = 'all_benefits';

exports.getAllBenefits = async (req, res) => {
  try {
    // Try Cache
    try {
      const cached = await redisClient.get(CACHE_KEY_BENEFITS);
      if (cached) return res.json(JSON.parse(cached));
    } catch (err) { console.error('Redis Get Benefits Error:', err); }

    const benefits = await prisma.siteBenefit.findMany({
      orderBy: { sort_order: 'asc' }
    });

    // Set Cache
    try {
      await redisClient.setEx(CACHE_KEY_BENEFITS, 86400, JSON.stringify(benefits));
    } catch (err) { console.error('Redis Set Benefits Error:', err); }

    res.json(benefits);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createBenefit = async (req, res) => {
  try {
    const { icon, title_uz, title_ru, title_en, is_active, sort_order } = req.body;
    const benefit = await prisma.siteBenefit.create({
      data: {
        icon,
        title_uz,
        title_ru,
        title_en,
        is_active: is_active !== undefined ? is_active : true,
        sort_order: parseInt(sort_order || 0)
      }
    });
    await redisClient.del(CACHE_KEY_BENEFITS);
    res.json(benefit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateBenefit = async (req, res) => {
  try {
    const { id } = req.params;
    const { icon, title_uz, title_ru, title_en, is_active, sort_order } = req.body;
    const benefit = await prisma.siteBenefit.update({
      where: { id },
      data: {
        icon,
        title_uz,
        title_ru,
        title_en,
        is_active,
        sort_order: sort_order !== undefined ? parseInt(sort_order) : undefined
      }
    });
    await redisClient.del(CACHE_KEY_BENEFITS);
    res.json(benefit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteBenefit = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.siteBenefit.delete({ where: { id } });
    await redisClient.del(CACHE_KEY_BENEFITS);
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
