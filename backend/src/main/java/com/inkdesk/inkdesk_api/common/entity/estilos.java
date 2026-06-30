package com.inkdesk.inkdesk_api.common.entity;

import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import lombok.Data;

@Entity
@Table(name = "estilos")
@Data
public class estilos {
    private String nombre;
}
