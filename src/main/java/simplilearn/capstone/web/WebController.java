package simplilearn.capstone.web;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class WebController {

    @RequestMapping("/home")
    public String home() {
      return "Hello Docker World";
    }
    
}
