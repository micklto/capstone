common
=========

Common configuration and installation tasks for the installation of a K3s cluster 

Requirements
------------

This role only uses Ansible builtin modules and has no separate requirements.

Tasks
--------------

- name: Apt update and apt upgrade, install packages
- name: Update to use aptitude
- name: Install packages that allow apt to be used over HTTPS
- name: Install prerequisities for kubernetes python package
- name: Install kubernetes python package
- name: Add an apt signing key for Docker
- name: Add apt repository for stable version
- name: Install docker and its dependecies

Author Information
------------------

tmickler@gmail.com
