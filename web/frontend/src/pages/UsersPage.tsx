import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import { Table } from '../components/ui/Table';
import { fetchUsers } from '../store/userSlice';

export const UsersPage = () => {
  const dispatch = useDispatch();
  const { users, loading } = useSelector((state: any) => state.user);

  useEffect(() => {
    dispatch(fetchUsers({ page: 1, limit: 10 }));
  }, [dispatch]);

  const columns = [
    { header: 'Username', accessor: 'username' },
    { header: 'Email', accessor: 'email' },
    { header: 'Created', accessor: 'createdAt' },
  ];

  return (
    <div className="p-6">
      <h1 className="text-3xl font-bold mb-6">Users</h1>
      <Table data={users} columns={columns} loading={loading} />
    </div>
  );
};
