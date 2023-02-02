master
=========

A collection of tasks to install the K3s master node.

Requirements
------------

This role only uses Ansible builtin modules and has no separate requirements.

Dependencies
------------

The ```common``` role is expected to run first.

Tasks
-------
- name: Download k3s
- name: Run k3s
- name: Setup kubeconfig for current(ansible?) user
- name: Generate token
- name: Copy join command to local file

Author Information
------------------

tmickler@gmail.com
