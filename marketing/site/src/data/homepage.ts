export const homepageContent = {
  hero: {
    eyebrow: 'Play more, coordinate less',
    title: 'Find time to play with friends without the clutter.',
    description:
      'InGame is a social gaming coordination app for private groups, invite links, join requests, and real-time coordination foundations.',
    primaryCta: { label: 'Open on Web', href: 'https://app.in-game.app' },
    secondaryCta: { label: 'See features', href: '#features' },
  },
  why: {
    eyebrow: 'Why InGame exists',
    title: 'A lighter way to coordinate gaming sessions.',
    body:
      'Group chats are noisy, timing is vague, and friend groups do not need a bloated community platform just to figure out when to play.',
  },
  features: [
    {
      title: 'Authentication',
      body: 'Email/password, Steam, and Apple sign-in help your group get in quickly.',
    },
    {
      title: 'Profiles',
      body: 'Set up your identity and availability so friends know who is ready.',
    },
    {
      title: 'Private groups',
      body: 'Coordinate with the people you actually play with, not a public community feed.',
    },
    {
      title: 'Invite links',
      body: 'Share a join link when you want to bring someone into the group fast.',
    },
    {
      title: 'Join requests',
      body: 'Keep access lightweight while still giving group owners control.',
    },
    {
      title: 'Real-time foundations',
      body: 'Presence and readiness signals help groups make faster decisions.',
    },
  ],
  steps: [
    'Create your account and complete your profile.',
    'Create a private group or join one from an invite.',
    'Use live coordination signals to find the right time to play.',
  ],
  platforms: {
    heading: 'Start anywhere. Stay coordinated everywhere.',
    description:
      'Open InGame instantly on web, then move to iOS or Android for a more native experience with live notifications and mobile-friendly coordination.',
    items: [
      { label: 'Web', body: 'The fastest way to get started right now.' },
      { label: 'iOS', body: 'A native mobile experience built for on-the-go coordination.' },
      { label: 'Android', body: 'A native mobile experience with the same focused product flow.' },
    ],
  },
  faq: [
    {
      question: 'What is InGame?',
      answer:
        'InGame is a focused coordination product for friend groups who want to find time to play together.',
    },
    {
      question: 'Do I need to install an app first?',
      answer:
        'No. You can open the web app immediately, then move to iOS or Android for the best native mobile experience.',
    },
  ],
  footer: {
    legalLinks: [
      { label: 'Privacy', href: '/privacy' },
      { label: 'Imprint', href: '/imprint' },
    ],
  },
} as const;
