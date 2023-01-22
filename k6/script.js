import http from 'k6/http';
import { sleep } from 'k6';

export default function () {
  http.get('http://139.144.164.21:8080/capstoneUsers');
  sleep(1);
}
