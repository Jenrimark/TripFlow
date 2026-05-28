package com.jenrimark.tripflow.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.jenrimark.tripflow.entity.User;
import com.jenrimark.tripflow.mapper.UserMapper;
import com.jenrimark.tripflow.service.UserService;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {
}
