package genZ.PRM393GenZ.security;

import genZ.PRM393GenZ.entity.User;
import genZ.PRM393GenZ.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản: " + email));

        // Dùng RoleId (ADMIN/STAFF/CUSTOMER) để khớp với hasRole('ADMIN');
        // RoleName là tên hiển thị ("Administrator") nên không dùng để phân quyền.
        String roleId = user.getRole() != null ? user.getRole().getRoleId() : "CUSTOMER";

        return org.springframework.security.core.userdetails.User.builder()
                .username(user.getEmail())
                .password(user.getPassword())
                .authorities(List.of(new SimpleGrantedAuthority("ROLE_" + roleId.toUpperCase())))
                .accountLocked(user.isLocked()) // Admin khoá thì không đăng nhập được
                .build();
    }
}
