package com.inkdesk.inkdesk_api.artist;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "tatuadores")
@Data
public class tatuador {
    private String nombre;
    private String email;
    private String password;
    private String ruta_foto_perfil;
    private String telefono;
    private String descripcion;
}
