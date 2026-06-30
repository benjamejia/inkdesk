package com.inkdesk.inkdesk_api.client;

import java.sql.Date;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "clientes")
@Data
public class cliente {
    private String nombre;
    private String telefono;
    private String correo;
    private Date fecha_nacimiento;
    private String notas;
}
