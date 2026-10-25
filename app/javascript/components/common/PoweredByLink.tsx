import * as React from 'react';
import I18n from 'i18n-js';

import { PROJECT_NAME, PROJECT_SHORT_NAME, PROJECT_REPOSITORY_URL } from '../../constants/project';

const PoweredByLink = () => (
  <div className="poweredBy">
    <a href={PROJECT_REPOSITORY_URL} target="_blank" rel="noreferrer">
      { I18n.t('common.powered_by') } { PROJECT_NAME } <span className="evoBadge">{ PROJECT_SHORT_NAME }</span>
    </a>
  </div>
);

export default PoweredByLink;
