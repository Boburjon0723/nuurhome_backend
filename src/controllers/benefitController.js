const prisma = require('../lib/prisma');

exports.getAllBenefits = async (req, res) => {
  try {
    const benefits = await prisma.siteBenefit.findMany({
      orderBy: { sort_order: 'asc' }
    });
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
    res.json(benefit);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deleteBenefit = async (req, res) => {
  try {
    const { id } = req.params;
    await prisma.siteBenefit.delete({ where: { id } });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
