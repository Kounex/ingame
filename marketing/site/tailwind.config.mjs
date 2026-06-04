export default {
  content: ['./src/**/*.{astro,html,js,ts,jsx,tsx,md,mdx}'],
  theme: {
    extend: {
      colors: {
        ig: {
          background: '#0A0E1A',
          surface: '#151B2E',
          primary: '#4FC3F7',
          secondary: '#B388FF',
        },
      },
      boxShadow: {
        glow: '0 12px 40px rgba(79, 195, 247, 0.22)',
      },
      borderRadius: {
        '2xl': '1rem',
        '3xl': '1.5rem',
      },
    },
  },
  plugins: [],
};
