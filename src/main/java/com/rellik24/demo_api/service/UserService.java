package com.rellik24.demo_api.service;

import com.rellik24.demo_api.entity.User;

public interface UserService {
    User createUser(User user);
    User getUserById(Long id);
    User getUserByEmail(String email);
} 