const prisma = require('../lib/prisma');

exports.getAllBanners = async (req, res) => {
  try {
    const banners = await prisma.banner.findMany({
      orderBy: { sort_order: 'asc' }
    });
    res.json(banners);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.createBanner = async (req, res) => {
  try {
    const { id, image_url, title_uz, title_ru, title_en, link_url, is_active, sort_order } = req.body;
    
    // Support upsert via ID if provided
    if (id) {
        const banner = await prisma.banner.upsert({
            where: { id },
            update: { image_url, title_uz, title_ru, title_en, link_url, is_active, sort_order: parseInt(sort_order || 0) },
            create: { image_url, title_uz, title_ru, title_en, link_url, is_active, sort_order: parseInt(sort_order || 0) }
        });
        return res.json(banner);
    }

    const banner = await prisma.banner.create({
      data: {
        image_url,
        title_uz,
        title_ru,
        title_en,
        link_url,
        is_active: is_active !== undefined ? is_active : true,
        sort_order: parseInt(sort_order || 0)
      }
    });
    res.json(banner);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteBanner = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.banner.delete({ where: { id } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
