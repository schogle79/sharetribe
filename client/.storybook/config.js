import { configure } from '@kadira/storybook';
import '../app/assets/styles/base.css';
import '../app/i18n/all';
import { initialize as initializeI18n } from '../app/utils/i18n';

// initializeI18n needs to know railsContext and node_env
initializeI18n('en', 'en', process.env.NODE_ENV);

const loadStories = function loadStories() {
  require('../app/components/Styleguide/ColorsAndTypography.js');
  require('../app/components/elements/Logo/Logo.story.js');
  require('../app/components/sections/Topbar/Topbar.story.js');
  require('../app/components/sections/OnboardingTopbar/OnboardingTopbar.story.js');
  require('../app/components/sections/OnboardingGuide/OnboardingGuide.story.js');
};

configure(loadStories, module);
