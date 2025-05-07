package com.rellik24.demo_api.services;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController()
@RequestMapping(value = "/person")
public class Person {
    @GetMapping
    void getPerson() {
        System.out.println("Person");
    }
}
