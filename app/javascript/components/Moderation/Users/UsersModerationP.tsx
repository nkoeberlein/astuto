import * as React from 'react';
import I18n from 'i18n-js';

import UserEditable from './UserEditable';
import Box from '../../common/Box';
import SiteSettingsInfoBox from '../../common/SiteSettingsInfoBox';

import { UsersState } from '../../../reducers/usersReducer';
import {
  UserRoles,
  UserStatuses,
  USER_ROLE_USER,
  USER_ROLE_MODERATOR,
  USER_ROLE_ADMIN,
  USER_ROLE_OWNER,
  USER_STATUS_ACTIVE,
  USER_STATUS_BLOCKED,
  USER_STATUS_DELETED,
} from '../../../interfaces/IUser';
import HttpStatus from '../../../constants/http_status';
import Spinner from '../../common/Spinner';

const FILTER_ALL = 'all';

interface Props {
  users: UsersState;
  settingsAreUpdating: boolean;
  settingsError: string;

  requestUsers(): void;
  updateUserRole(
    id: number,
    role: UserRoles,
    authenticityToken: string,
  ): Promise<any>;
  updateUserStatus(
    id: number,
    status: typeof USER_STATUS_ACTIVE | typeof USER_STATUS_BLOCKED,
    authenticityToken: string,
  ): void;

  currentUserEmail: string;
  currentUserRole: UserRoles;
  authenticityToken: string;
}

interface State {
  searchQuery: string;
  statusFilter: UserStatuses | typeof FILTER_ALL;
  roleFilter: UserRoles | typeof FILTER_ALL;
}

class UsersModerationP extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props);

    this.state = {
      searchQuery: '',
      statusFilter: FILTER_ALL,
      roleFilter: FILTER_ALL,
    };

    this._handleUpdateUserRole = this._handleUpdateUserRole.bind(this);
    this._handleUpdateUserStatus = this._handleUpdateUserStatus.bind(this);
    this._handleSearchChange = this._handleSearchChange.bind(this);
    this._handleStatusChange = this._handleStatusChange.bind(this);
    this._handleRoleChange = this._handleRoleChange.bind(this);
  }

  componentDidMount() {
    this.props.requestUsers();
  }

  _handleUpdateUserRole(id: number, role: UserRoles, closeEditMode: Function) {
    this.props.updateUserRole(
      id,
      role,
      this.props.authenticityToken,
    ).then(res => {
      if (res?.status !== HttpStatus.OK) return;

      closeEditMode();
    });
  }

  _handleUpdateUserStatus(id: number, status: typeof USER_STATUS_ACTIVE | typeof USER_STATUS_BLOCKED) {
    this.props.updateUserStatus(
      id,
      status,
      this.props.authenticityToken,
    );
  }

  _handleSearchChange(event: React.ChangeEvent<HTMLInputElement>) {
    this.setState({ searchQuery: event.target.value });
  }

  _handleStatusChange(event: React.ChangeEvent<HTMLSelectElement>) {
    this.setState({ statusFilter: event.target.value as State['statusFilter'] });
  }

  _handleRoleChange(event: React.ChangeEvent<HTMLSelectElement>) {
    this.setState({ roleFilter: event.target.value as State['roleFilter'] });
  }

  render() {
    const {
      users,
      settingsAreUpdating,
      settingsError,
      currentUserRole,
      currentUserEmail,
    } = this.props;
    const { searchQuery, statusFilter, roleFilter } = this.state;

    const numberOfUsers = users.items.length;
    const numberOfActiveUsers = users.items.filter(u => u.status === USER_STATUS_ACTIVE).length;
    const numberOfBlockedUsers = users.items.filter(u => u.status === USER_STATUS_BLOCKED).length;
    const numberOfDeletedUsers = users.items.filter(u => u.status === USER_STATUS_DELETED).length;

    const query = searchQuery.trim().toLowerCase();
    const filteredUsers = users.items.filter((user) => {
      const matchesSearch =
        query === '' ||
        user.email.toLowerCase().includes(query) ||
        (user.fullName || '').toLowerCase().includes(query);
      const matchesStatus = statusFilter === FILTER_ALL || user.status === statusFilter;
      const matchesRole = roleFilter === FILTER_ALL || user.role === roleFilter;

      return matchesSearch && matchesStatus && matchesRole;
    });

    return (
      <>
        <Box>
          <h2>{I18n.t('moderation.users.title')}</h2>
          <div className="usersFilters">
            <input
              type="text"
              className="form-control"
              placeholder={I18n.t('moderation.users.search_placeholder')}
              value={searchQuery}
              onChange={this._handleSearchChange}
            />
            <select className="selectPicker" value={statusFilter} onChange={this._handleStatusChange}>
              <option value={FILTER_ALL}>{I18n.t('moderation.users.filter_all_statuses')}</option>
              <option value={USER_STATUS_ACTIVE}>{I18n.t('moderation.users.status_active')}</option>
              <option value={USER_STATUS_BLOCKED}>{I18n.t('moderation.users.status_blocked')}</option>
              <option value={USER_STATUS_DELETED}>{I18n.t('moderation.users.status_deleted')}</option>
            </select>
            <select className="selectPicker" value={roleFilter} onChange={this._handleRoleChange}>
              <option value={FILTER_ALL}>{I18n.t('moderation.users.filter_all_roles')}</option>
              <option value={USER_ROLE_OWNER}>{I18n.t('moderation.users.role_owner')}</option>
              <option value={USER_ROLE_ADMIN}>{I18n.t('moderation.users.role_admin')}</option>
              <option value={USER_ROLE_MODERATOR}>{I18n.t('moderation.users.role_moderator')}</option>
              <option value={USER_ROLE_USER}>{I18n.t('moderation.users.role_user')}</option>
            </select>
          </div>

          <p className="userCount">
            {numberOfUsers} {I18n.t('activerecord.models.user', { count: numberOfUsers })} (
            {numberOfActiveUsers} {I18n.t('moderation.users.status_active')},&nbsp;
            {numberOfBlockedUsers} {I18n.t('moderation.users.status_blocked')},&nbsp;
            {numberOfDeletedUsers} {I18n.t('moderation.users.status_deleted')})
          </p>

          <ul className="usersList">
            {
              users.areLoading === false ?
                filteredUsers.map(user => (
                  <UserEditable
                    user={user}
                    updateUserRole={this._handleUpdateUserRole}
                    updateUserStatus={this._handleUpdateUserStatus}

                    currentUserEmail={currentUserEmail}
                    currentUserRole={currentUserRole}
                    key={user.id}
                  />
                ))
                :
                <Spinner />
            }
          </ul>
        </Box>

        <SiteSettingsInfoBox areUpdating={settingsAreUpdating || users.areLoading} error={settingsError} />
      </>
    );
  }
}

export default UsersModerationP;