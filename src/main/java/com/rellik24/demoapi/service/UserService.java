package com.rellik24.demoapi.service;

import com.rellik24.demoapi.entity.User;

public interface UserService {
    User createUser(User user);
    User getUserById(Long id);
    User getUserByEmail(String email);
} 