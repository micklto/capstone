[control_nodes]
%{ for ip in control_nodes   ~}
${ip}
%{ endfor ~}

[worker_nodes]
%{ for ip in worker_nodes ~}
${ip}
%{ endfor ~}