deployments
=========

Ansible role that creates the ```PostgreSQL``` and ```capstone``` deployments in Kubernetes.

Requirements
------------

The [kubernetes.core.k8s module](https://docs.ansible.com/ansible/latest/collections/kubernetes/core/k8s_module.html#ansible-collections-kubernetes-core-k8s-module-requirements) is leveraged in the ```deployments``` role and the prerequisties will be installed during the execution of the ```common``` role.

Role Variables
--------------

This role defines a default of ```app_namespace```.  This is the name of the namespace in which the Kubernetes objects are created.

Dependencies
------------

The ```common``` , ```master```, and ```worker``` roles are expected to run first.

Tasks
-------

- name: Copy deploy directory to remote
- name: Print out the namespace before using it
- name: Create a k8s namespace
- name: Apply Postgres configuration
- name: Apply Postgres Persistent Volume Claim
- name: Apply Postgres deployment
- name: Create Postgres Service
- name: Create capstone deployment
- name: Create capstone service
- name: Define HorizontalPodAutoscalar

Author Information
------------------

tmickler@gmail.com
